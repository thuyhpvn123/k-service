package repositories

import (
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	"gorm.io/gorm"
	"fmt"
)

type EBuyProductDataRepository struct {
	db *gorm.DB
}

func NewEBuyProductDataRepository(db *gorm.DB) *EBuyProductDataRepository {
	return &EBuyProductDataRepository{db}
}

func (repo *EBuyProductDataRepository) CreateEBuyProductData(EBuyProductData *models.EBuyProductDataHistory) error {
	return repo.db.Create(EBuyProductData).Error
}

func (repo *EBuyProductDataRepository) GetEBuyProductDataByAddress(address string) ([]*models.EBuyProductDataHistory, error) {
	var histories = []*models.EBuyProductDataHistory{}
	result := repo.db.Where("`add` like ?", "%"+address+"%").Find(&histories)
	if result.Error == gorm.ErrRecordNotFound {
		return nil, result.Error
	}
	return histories, result.Error
}
func (repo *EBuyProductDataRepository) GetEBuyProductDataByAddressAndTime (address string,from int, to int) ([]*models.EBuyProductDataHistory, error) {
	var histories = []*models.EBuyProductDataHistory{}
	result := repo.db.Where("`add` like ?", "%"+address+"%").Where("time >= ? AND time <= ?", from, to).Find(&histories)
	if result.Error == gorm.ErrRecordNotFound {
		return nil, result.Error
	}
	fmt.Println("histories la:",histories)
	return histories, result.Error
}