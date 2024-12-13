package models

type UserInfo struct {
	ID                          int `gorm:"primary_key" json:"id"`
	Index                       uint
	Add                         string `gorm:"column:address"`
	FirstTimePay                uint
	NextTimePay                 uint
	Month                       uint
	Phone                       string
	ChildsDirect                string
	ChildsMatrix                string
	Line                        string
	LineMatrix                  string
	MtotalMember                uint `gorm:"column:total_childrens_direct"`
	TotalChildrensMatrix        uint
	Rank                        uint
	TotalSubcriptionBonus       uint
	TotalMatrixBonus            uint
	TotalMatchingBonus          uint
	TotalSaleBonus              uint
	TotalGoodSaleBonus          uint
	TotalExtraDiamondBonus      uint
	TotalExtraCrownDiamondBonus uint
	TotalRevenues               uint
	TotalSale                   uint
	UserName					string
	IsActive					bool
}
