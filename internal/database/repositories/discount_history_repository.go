package repositories

import (
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	"gorm.io/gorm"
)

type DiscountHistoryRepository struct {
	db *gorm.DB
}

func NewDiscountHistoryRepository(db *gorm.DB) *DiscountHistoryRepository {
	return &DiscountHistoryRepository{db}
}

func (repo *DiscountHistoryRepository) CreateDiscountHistory(DiscountHistory *models.DiscountHistory) error {
	return repo.db.Create(DiscountHistory).Error
}

func (repo *DiscountHistoryRepository) GetDiscountHistoryByAddress(address string) ([]*models.DiscountHistory, error) {
	var histories = []*models.DiscountHistory{}
	result := repo.db.Where("link = ?", address).Find(&histories)
	if result.Error == gorm.ErrRecordNotFound {
		return nil, result.Error
	}
	return histories, result.Error
}
