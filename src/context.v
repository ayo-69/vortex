module vortex

import net.http
import time

pub struct Context {
pub mut:
	req http.Request
	resp http.Response = http.Response{
		header: http.new_header()
		http_version: 'HTTP/1.1'
		status_code: 200
		status_msg: 'OK'
	}

	params map[string]string
	data map[string]voidptr
	start_mono i64 = time.sys_mono_now()
	index int = -1
}

pub fn (mut ctx Context) json(data string) {
	ctx.resp.header.add(.content_type, 'application/json')
	ctx.resp.body = data
}

pub fn (mut ctx Context) text(str string) {
	ctx.resp.header.add(.content_type, 'text/plain')
	ctx.resp.body = str
}

pub fn (mut ctx Context) status(status http.Status) {
	ctx.resp.set_status(status)
}

pub fn (mut ctx Context) not_found() {
	ctx.status(.not_found)
	ctx.text('404 - Not Found')
}

pub fn (mut ctx Context) server_error(msg string) {
	ctx.status(.internal_server_error)
	ctx.text('500 - ${msg}')
}
