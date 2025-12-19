module auth

import crypto.hmac
import crypto.sha256
import encoding.base64
import json
import time

// TODO: Find a way to get the dev to pass in their secret_key
const secret_key = 'secret_key'
const expiration = 24 * time.hour

fn base64_url_encode(input []u8) string {
	return base64.url_encode(input).trim_right('=')
}

pub fn generate_token(user User) string {
	header := base64_url_encode('{"alg":"HS256", "typ":"JWT"}'.bytes())

	iat := time.now().unix()
	exp := iat + expiration

	claims := Claims{
		sub:   user.id.str()
		name:  user.username
		email: user.email
		role:  user.role
		exp:   exp
	}

	payload := base64_url_encode(json.encode(claims).bytes())

	signing_input := '${header}.${payload}'
	signature := hmac.new(secret_key.bytes(), signing_input.bytes(), sha256.sum, sha256.block_size)
	signed := base64_url_encode(signature)

	return '${header}.${payload}.${signed}'
}

pub fn verify_token(token string) !map[string]string {
	parts := token.split('.')
	if parts.len != 3 {
		return error('invalid token format')
	}

	header_payload := '${parts[0]}.${parts[1]}'
	expected_sig := hmac.new(secret_key.bytes(), header_payload.bytes(), sha256.sum, sha256.block_size)

	mut sig_str := parts[2]
	match sig_str.len % 4 {
		2 { sig_str += '==' }
		3 { sig_str += '=' }
		else {}
	}
	provided_sig := base64.url_decode(parts[2] + '==')

	if !hmac.equal(expected_sig, provided_sig) {
		return error('invalid signature')
	}

	mut payload_str := parts[2]
	match sig_str.len % 4 {
		2 { payload_str += '==' }
		3 { payload_str += '=' }
		else {}
	}

	payload_bytes := base64.url_decode(payload_str)
	claims := json.decode(Claims, payload_bytes.bytestr()) or { return error('invalid payload') }

	if time.unix(claims.exp) < time.now() {
		return error('token expired')
	}

	return {
		'user_id':  claims.sub
		'username': claims.name
		'email':    claims.email
		'role':     claims.role
	}
}
