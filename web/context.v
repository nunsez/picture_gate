module web

import net.urllib
import veb
import datastar.datastar_veb

pub struct Context {
	veb.Context
}

fn (mut ctx Context) datastar_remove(selector string) !veb.Result {
	return datastar_veb.patch_elements(mut ctx.Context, '', selector: selector, mode: .remove)
}

fn (mut ctx Context) datastar_script(script string) !veb.Result {
	return datastar_veb.execute_script(mut ctx.Context, script)
}

// TODO: simplify (net.urllib research)
pub fn (ctx &Context) build_page_url(page u64) string {
	mut params := ctx.query.clone()
	params['page'] = page.str()

	mut parts := []string{cap: params.len}
	for k, v in params {
		parts << '${urllib.query_escape(k)}=${urllib.query_escape(v)}'
	}
	parts.sort()

	path := ctx.req.url.all_before('?')
	q := parts.join('&')
	return if q == '' { path } else { '${path}?${q}' }
}
