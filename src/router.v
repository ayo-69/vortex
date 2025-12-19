module vortex

import net.http

pub struct RouteNode {
pub mut:
	path string
	middleware []Middleware
	handler HandlerFn = unsafe { nil }
	children map[string]&RouteNode
	param_child &RouteNode = unsafe { nil }
	wildcard &RouteNode = unsafe { nil }
	param_name string
}

pub struct Router {
pub mut:
	trees map[string]&RouteNode
	not_found HandlerFn = fn (mut ctx Context) bool {
		ctx.not_found()
		return false
	}
}

pub fn new_router() &Router {
	return &Router{
		trees: map[string]&RouteNode{},
	}
}

pub fn (mut r Router) register(method string, path string, handler HandlerFn, mids []Middleware) {
	mut current_node := r.trees[method] or {
		r.trees[method] = &RouteNode{}
		r.trees[method]
	}

	if path == '/' {
		current_node.handler = handler
		current_node.middleware = mids
		return
	}

	segments := path.split('/')[1..]

	for i, segment in segments {
		if segment.len == 0 {
			continue
		}

		mut child := &RouteNode{}
		if segment.starts_with(':') {
			if current_node.param_child == unsafe { nil } {
				current_node.param_child = &RouteNode{
					path: segment,
					param_name: segment[1..],
				}
			}
			child = current_node.param_child
		} else if segment.starts_with('*') {
			if current_node.wildcard == unsafe { nil } {
				current_node.wildcard = &RouteNode{
					path: segment,
					param_name: segment[1..],
				}
			}
			child = current_node.wildcard
		} else {
			if segment in current_node.children {
				child = current_node.children[segment]
			} else {
				child = &RouteNode{
					path: segment,
				}
				current_node.children[segment] = child
			}
		}

		current_node = child

		if i == segments.len - 1 {
			current_node.handler = handler
			current_node.middleware = mids
		}
	}
}

pub fn (r &Router) match(req http.Request) ?(HandlerFn, []Middleware, map[string]string) {
	method := req.method.str()
	path := req.url

	if tree := r.trees[method] {
		segments := path.split('/')[1..]
		mut params := map[string]string{}

		mut current_node := tree
		for i, segment in segments {
			if segment.len == 0 {
				continue
			}

			if child := current_node.children[segment] {
				current_node = child
			} else if current_node.param_child != unsafe { nil } {
				current_node = current_node.param_child
				params[current_node.param_name] = segment
			} else if current_node.wildcard != unsafe { nil } {
				current_node = current_node.wildcard
				params[current_node.param_name] = segments[i..].join('/')
				break
			} else {
				return none
			}
		}

		if current_node.handler != unsafe { nil } {
			return current_node.handler, current_node.middleware, params
		}
	}

	return none
}

pub struct RouterGroup {
pub mut:
	router &Router
	prefix string
	middleware []Middleware
}
pub fn (mut r Router) group(prefix string, mids ...Middleware) &RouterGroup {
	return &RouterGroup{
		router: r,
		prefix: prefix,
		middleware: mids,
	}
}

pub fn (mut g RouterGroup) handle(method string, path string, handler HandlerFn, mids ...Middleware) {
	mut combined_middleware := g.middleware.clone()
	combined_middleware << mids
	g.router.register(method, g.prefix + path, handler, combined_middleware)
}

pub fn (mut g RouterGroup) get(path string, handler HandlerFn, mids ...Middleware) {
	g.handle('GET', path, handler, ...mids)
}

pub fn (mut g RouterGroup) post(path string, handler HandlerFn, mids ...Middleware) {
	g.handle('POST', path, handler, ...mids)
}

pub fn (mut g RouterGroup) put(path string, handler HandlerFn, mids ...Middleware) {
	g.handle('PUT', path, handler, ...mids)
}

pub fn (mut g RouterGroup) delete(path string, handler HandlerFn, mids ...Middleware) {
	g.handle('DELETE', path, handler, ...mids)
}
