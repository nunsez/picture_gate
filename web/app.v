module web

import config
import db.sqlite
import veb

pub fn run(port u16, cfg config.Config, cfg_path string, pool sqlite.ConnectionPool) ! {
	mut app := App{ pool: pool, cfg: cfg, cfg_path: cfg_path }

	app.enable_static_compression = true
	app.mount_static_folder_at('static', '/public')!

	veb.run[App, Context](mut app, port)
}

pub struct App {
	veb.StaticHandler
	pool     sqlite.ConnectionPool
	cfg      config.Config
	cfg_path string
}

@[params]
struct LayoutParams {
	layout  string = 'main'
	title   string = 'Picture Gate'
	content string
}

fn (app &App) render_layout(params LayoutParams) string {
	return $tmpl('templates/layouts/main.html')
}
