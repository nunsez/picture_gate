module web

enum PageKind {
	pending
	accepted
	declined
}

fn PageKind.from_ctx(ctx Context) !PageKind {
	return PageKind.from(ctx.form['pageKind'])!
}
