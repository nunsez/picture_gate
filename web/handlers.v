module web

import db.sqlite
import strconv
import veb
import core
import walk

const per_page = 30

@['/']
pub fn (app &App) index(mut ctx Context) !veb.Result {
	picture := core.random_pending(mut app.pool) or {
		html := app.render_layout(content: '<p style="text-align: center;">No More Pending!</p>')
		return ctx.html(html)
	}

	html := app.render_layout(content: $tmpl('templates/pending.html'))
	return ctx.html(html)
}

@['/declined']
pub fn (app &App) declined(mut ctx Context) !veb.Result {
	page := strconv.atou32(ctx.query['page'] or { '1' })!
	q := (ctx.query['q'] or { '' }).trim_space()
	result := core.by_status(mut app.pool, .declined, limit: per_page, page: page, q: q)!
	pagination := core.new_pagination(
		current_page: page
		total_items:  result.count
		per_page:     per_page
	)
	html := app.render_layout(content: $tmpl('templates/declined.html'))
	return ctx.html(html)
}

@['/accepted']
pub fn (app &App) accepted(mut ctx Context) !veb.Result {
	page := strconv.atou32(ctx.query['page'] or { '1' })!
	q := (ctx.query['q'] or { '' }).trim_space()
	result := core.by_status(mut app.pool, .accepted, limit: per_page, page: page, q: q)!
	pagination := core.new_pagination(
		current_page: page
		total_items:  result.count
		per_page:     per_page
	)
	html := app.render_layout(content: $tmpl('templates/accepted.html'))
	return ctx.html(html)
}

@['/accept/:id'; patch]
pub fn (app &App) accept(mut ctx Context, id i64) !veb.Result {
	kind := PageKind.from_ctx(ctx) or {
		return ctx.request_error('bad kind')
	}

	core.set_status(mut app.pool, id, .accepted) or {
		return ctx.request_error(err.str())
	}

	match kind {
		.pending { return ctx.redirect('/', typ: .see_other) }
		.declined {
			selector := '#${core.Picture.dom_id(id)}'
			return ctx.datastar_remove(selector)
		}
		else { return ctx.request_error('bad kind') }
	}
}

@['/decline/:id'; patch]
pub fn (app &App) decline(mut ctx Context, id i64) !veb.Result {
	kind := PageKind.from_ctx(ctx) or {
		return ctx.request_error('bad kind')
	}

	core.set_status(mut app.pool, id, .declined) or {
		return ctx.request_error(err.str())
	}

	match kind {
		.pending { return ctx.redirect('/', typ: .see_other) }
		.accepted {
			selector := '#${core.Picture.dom_id(id)}'
			return ctx.datastar_remove(selector)
		}
		else { return ctx.request_error('') }
	}
}

@['/pending/:id'; patch]
pub fn (app &App) pending(mut ctx Context, id i64) !veb.Result {
	kind := PageKind.from_ctx(ctx) or {
		return ctx.request_error('bad kind')
	}

	core.set_status(mut app.pool, id, .pending) or {
		return ctx.request_error(err.str())
	}

	match kind {
		.accepted, .declined {
			selector := '#${core.Picture.dom_id(id)}'
			return ctx.datastar_remove(selector)
		}
		else { return ctx.request_error('') }
	}
}

@['/scan'; post]
pub fn (app &App) scan(mut ctx Context) !veb.Result {
	spawn handle_scan(app.cfg_path, mut &app.pool)
	return ctx.redirect('/')
}

fn handle_scan(cfg_path string, mut pool sqlite.ConnectionPool) {
	mut conn := pool.acquire() or { return }
	defer { pool.release(conn) }

	walk.run_with_new_config(cfg_path, mut conn) or {
		eprintln('run with config error: ${err}')
		return
	}
}

@['/sfw/:id'; post]
pub fn (app &App) sfw(mut ctx Context, id i64) !veb.Result {
	kind := PageKind.from_ctx(ctx) or {
		return ctx.request_error('bad kind')
	}

	core.sfw(mut app.pool, id) or {
		return ctx.datastar_script('alert("${err}")')
	}

	match kind {
		.pending { return ctx.redirect('/') }
		.accepted, .declined {
			selector := '#${core.Picture.dom_id(id)}'
			return ctx.datastar_remove(selector)
		}
	}
}

// FIXME: send only needed pictures, not any files
@['/:path...']
pub fn (app &App) fallback(mut ctx Context, path string) veb.Result {
	for wc in app.cfg.walk {
		override := wc.override or { continue }
		if path.starts_with(wc.root) {
			overrided := path.replace_once(wc.root, override)
			return ctx.file(overrided)
		}
	}
	return ctx.file(path)
}
