
variable "location" {
  default = "eastus"
}


variable "users" {
    type = map(any)
    default =  {
  user1 = {
    display = "dev"
    department = "Developers"
  }
  user2 = {
    display = "administrator"
    department = "Admins"
  }

  user3 = {
    display = "guest"
    department = "Guests"
  }
}
}