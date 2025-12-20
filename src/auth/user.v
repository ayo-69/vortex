module auth

pub struct User {
pub:
	id       int
	username string
	email    string
	role     string = 'user'
	// TODO: Add more fields later
}

pub struct Claims {
pub:
	sub   string
	name  string
	email string
	role  string
	exp   i64 //  expiratoin
}
