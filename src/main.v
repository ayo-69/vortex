module main

import vortex
import time
import auth
import json

struct AuthUser {
	user_id  string
	username string
	email    string
	role     string
}

struct MeResponse {
	message string
	user    AuthUser
}

fn main() {
	mut app := &vortex.App{}

	app.use(vortex.logging())

	mut api := app.router.group('/api/v1')

	api.get('/hello', fn (mut ctx vortex.Context) bool {
		ctx.json('{"message": "Hello from vortex!", "time": "${time.now}"}')
		return false
	})

	api.get('/ping', fn (mut ctx vortex.Context) bool {
		ctx.text('pong')
		return false
	})

	api.put('/put', fn (mut ctx vortex.Context) bool {
		ctx.json({
			'message': 'updated something'
		})
		return false
	})

	api.get('/users/:id', fn (mut ctx vortex.Context) bool {
		id := ctx.params['id'] or { 'unknown' }
		ctx.json('{"message": "user requested", "id": "${id}"}')
		return false
	})

	api.get('/files/*filepath', fn (mut ctx vortex.Context) bool {
		filepath := ctx.params['filepath'] or { 'none' }
		ctx.text('serving file from: ${filepath}')
		return false
	})

	api.get('/auth/login', fn (mut ctx vortex.Context) bool {
		user := auth.User{
			id:       42
			username: 'ayo'
			email:    'ayo@ayo.com'
			role:     'admin'
		}

		token := auth.generate_token(user)

		user_map := {
			'id':       '${user.id}'
			'username': user.username
			'role':     user.role
		}

		mut response := map[string]string{}
		response['token'] = token
		response['user'] = json.encode(user_map)

		ctx.json(response)
		return false
	})

	api.get('/me', fn (mut ctx vortex.Context) bool {
		user := AuthUser{
			user_id:  ctx.data['user_id']
			role:     ctx.data['role']
			username: ctx.data['username']
			email:    ctx.data['email']
		}

		response := MeResponse{
			message: 'Welcome back'
			user:    user
		}

		ctx.json(user)
		return false
	}, auth.require_auth())

	app.serve() or { panic('Failed to start; ${err}') }
}
