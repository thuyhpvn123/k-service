package repositories

import (
	"gorm.io/gorm"
)

type Repositories struct {
	BonusHistory    *BonusHistoryRepository
	DiscountHistory *DiscountHistoryRepository
	EBuyProductDataHistory *EBuyProductDataRepository
	SubInfoHistory *SubInfoRepository
	LogHistory *LogRepository
	LogStatusHistory *LogStatusRepository
}

func NewRepositories(db *gorm.DB) *Repositories {
	return &Repositories{
		BonusHistory:    NewBonusHistoryRepository(db),
		DiscountHistory: NewDiscountHistoryRepository(db),
		EBuyProductDataHistory: NewEBuyProductDataRepository(db),
		SubInfoHistory: NewSubInfoRepository(db),
		LogHistory :  NewLogRepository(db),
		LogStatusHistory : NewLogStatusRepository(db),
	}
}
