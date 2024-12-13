package repositories

import (
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	"gorm.io/gorm"
)

type BonusHistoryRepository struct {
	db *gorm.DB
}

func NewBonusHistoryRepository(db *gorm.DB) *BonusHistoryRepository {
	return &BonusHistoryRepository{db}
}

func (repo *BonusHistoryRepository) CreateBonusHistory(BonusHistory *models.BonusHistory) error {
	return repo.db.Create(BonusHistory).Error
}

func (repo *BonusHistoryRepository) CreateBonusHistoryBatch(BonusHistory []*models.BonusHistory, batchSize int) error {
	return repo.db.CreateInBatches(BonusHistory, batchSize).Error
}

func (repo *BonusHistoryRepository) GetBonusHistoryByAddressAndType(address string, typ string) ([]*models.BonusHistory, error) {
	var histories = []*models.BonusHistory{}
	result := repo.db.Where("address like ?", "%"+address+"%").Where("type = ?", typ).Order("time desc").Find(&histories)
	if result.Error == gorm.ErrRecordNotFound {
		return nil, result.Error
	}
	return histories, result.Error
}

func (repo *BonusHistoryRepository) GetBonusHistoryByAddress(address string) ([]*models.BonusHistory, error) {
	var histories = []*models.BonusHistory{}
	result := repo.db.Where("address like ?", "%"+address+"%").Order("time desc").Find(&histories)
	if result.Error == gorm.ErrRecordNotFound {
		return nil, result.Error
	}
	return histories, result.Error
}
func (repo *BonusHistoryRepository) GetBonusHistoryByAddressAndTypeTime(address string, typ string, from int, to int) ([]*models.BonusHistory, error) {
	var histories = []*models.BonusHistory{}
	result := repo.db.Where("address like ?", "%"+address+"%").Where("type = ? AND time >= ? AND time <=?", typ, from, to).Order("time desc").Find(&histories)
	if result.Error == gorm.ErrRecordNotFound {
		return nil, result.Error
	}
	return histories, result.Error
}
func (repo *BonusHistoryRepository) GetBonusHistoryByAddressAndTime(address string, from int, to int) ([]*models.BonusHistory, error) {
	var histories = []*models.BonusHistory{}
	result := repo.db.Where("address like ?", "%"+address+"%").Where("time >= ? AND time <= ?", from, to).Order("time desc").Find(&histories)
	if result.Error == gorm.ErrRecordNotFound {
		return nil, result.Error
	}
	return histories, result.Error
}
