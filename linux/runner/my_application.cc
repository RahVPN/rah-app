#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <libayatana-appindicator/app-indicator.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static AppIndicator* tray_indicator = nullptr;
static FlMethodChannel* tray_channel = nullptr;
static GtkWidget* tray_connection_item = nullptr;

static void show_window_cb(GtkMenuItem* item, gpointer user_data) {
  GtkWindow* window = GTK_WINDOW(user_data);
  gtk_window_present(window);
}

static void tray_toggle_cb(GtkMenuItem* item, gpointer user_data) {
  if (tray_channel == nullptr) return;
  fl_method_channel_invoke_method(tray_channel, "toggleConnection", nullptr,
                                 nullptr, nullptr, nullptr);
}

static void tray_quit_response_cb(GObject* object,
                                  GAsyncResult* result,
                                  gpointer user_data) {
  auto* channel = FL_METHOD_CHANNEL(object);
  GtkWindow* window = GTK_WINDOW(user_data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response =
      fl_method_channel_invoke_method_finish(channel, result, &error);
  if (error != nullptr) {
    g_warning("Could not stop RahVPN before closing: %s", error->message);
  }
  gtk_window_close(window);
  g_object_unref(window);
}

static void tray_quit_cb(GtkMenuItem* item, gpointer user_data) {
  if (tray_channel == nullptr) {
    gtk_window_close(GTK_WINDOW(user_data));
    return;
  }
  fl_method_channel_invoke_method(
      tray_channel, "quitApplication", nullptr, nullptr,
      tray_quit_response_cb, g_object_ref(user_data));
}

static void tray_method_call_cb(FlMethodChannel* channel,
                                FlMethodCall* method_call,
                                gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);
  if (g_strcmp0(method, "setConnectionState") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    const gchar* state =
        args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_STRING
            ? fl_value_get_string(args)
            : "idle";
    const gchar* label = "Connect";
    gboolean enabled = TRUE;
    if (g_strcmp0(state, "connected") == 0) {
      label = "Disconnect";
    } else if (g_strcmp0(state, "starting") == 0) {
      label = "Cancel connection";
    } else if (g_strcmp0(state, "stopping") == 0) {
      label = "Disconnecting...";
      enabled = FALSE;
    }
    gtk_menu_item_set_label(GTK_MENU_ITEM(tray_connection_item), label);
    gtk_widget_set_sensitive(tray_connection_item, enabled);
    fl_method_call_respond_success(method_call, nullptr, nullptr);
    return;
  }
  fl_method_call_respond_not_implemented(method_call, nullptr);
}

static void create_tray_indicator(GtkWindow* window, FlView* view) {
  if (tray_indicator != nullptr) return;

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  tray_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "com.rahvpn/tray", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      tray_channel, tray_method_call_cb, nullptr, nullptr);

  g_autofree gchar* executable_path = g_file_read_link("/proc/self/exe", nullptr);
  if (executable_path == nullptr) return;
  g_autofree gchar* executable_dir = g_path_get_dirname(executable_path);
  g_autofree gchar* icon_dir = g_build_filename(executable_dir, "data", nullptr);
  gtk_icon_theme_append_search_path(gtk_icon_theme_get_default(), icon_dir);

  tray_indicator = APP_INDICATOR(g_object_new(
      APP_INDICATOR_TYPE, "id", "com.rahvpn", "category",
      "ApplicationStatus", "icon-name", "rahvpn", "icon-theme-path",
      icon_dir, nullptr));
  app_indicator_set_title(tray_indicator, "RahVPN");
  app_indicator_set_status(tray_indicator, APP_INDICATOR_STATUS_ACTIVE);

  GtkWidget* menu = gtk_menu_new();
  GtkWidget* open_item = gtk_menu_item_new_with_label("Open RahVPN");
  g_signal_connect(open_item, "activate", G_CALLBACK(show_window_cb), window);
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), open_item);
  tray_connection_item = gtk_menu_item_new_with_label("Connect");
  g_signal_connect(tray_connection_item, "activate",
                   G_CALLBACK(tray_toggle_cb), nullptr);
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), tray_connection_item);
  GtkWidget* close_item = gtk_menu_item_new_with_label("Close RahVPN");
  g_signal_connect(close_item, "activate", G_CALLBACK(tray_quit_cb), window);
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), close_item);
  gtk_widget_show_all(menu);
  app_indicator_set_menu(tray_indicator, GTK_MENU(menu));
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // GTK window icon for task bars and window switchers. Resolve it beside the
  // installed bundle so this works from any current working directory.
  g_autofree gchar* executable_path = g_file_read_link("/proc/self/exe", nullptr);
  if (executable_path != nullptr) {
    g_autofree gchar* executable_dir = g_path_get_dirname(executable_path);
    g_autofree gchar* icon_path =
        g_build_filename(executable_dir, "data", "rahvpn.png", nullptr);
    if (g_file_test(icon_path, G_FILE_TEST_IS_REGULAR)) {
      g_autoptr(GError) icon_error = nullptr;
      if (!gtk_window_set_icon_from_file(window, icon_path, &icon_error)) {
        g_warning("Could not load RahVPN window icon: %s", icon_error->message);
      }
    }
  }

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Rah VPN");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Rah VPN");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  create_tray_indicator(window, view);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", 0, nullptr));
}
