package models;
type LogHistory struct{
	ID 			int `gorm:"primary_key" json:"id"`
	Address		string
	TimeLogIn 	uint
	TimeLogOut 	uint
	TimeUse		uint
}
type LogStatus struct{
	ID int`gorm:"primary_key" json:"id"`
	Address string
	LastLogin uint
}