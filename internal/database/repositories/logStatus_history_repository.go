package repositories

import (
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	"gorm.io/gorm"
	// "errors"
)

type LogStatusRepository struct {
	db *gorm.DB
}

func NewLogStatusRepository(db *gorm.DB) *LogStatusRepository {
	return &LogStatusRepository{db}
}

func (repo *LogStatusRepository) CreateLogStatus(LogStatus *models.LogStatus) error {
	return repo.db.Create(LogStatus).Error
}

func (repo *LogStatusRepository) GetLastLogStatusByAddress(address string) (*models.LogStatus, error) {
	var history *models.LogStatus
	result := repo.db.Model(&models.LogStatus{}).Where("address LIKE ?", "%"+address+"%").Last(&history)
	if result.Error == gorm.ErrRecordNotFound {
		return nil, result.Error
	}
	return history, result.Error
}

// GetLogStatusByAddressAndTime to get number of children from time to time
func (repo *LogStatusRepository) GetLastLogStatusByAddressAndTime(address string, from int, to int) (*models.LogStatus, error) {
	var history *models.LogStatus
	result := repo.db.Model(&models.LogStatus{}).
		Where("address LIKE ?", "%"+address+"%").
		Where("time >= ? AND time <=?", from, to).
		Last(&history)
	if result.Error == gorm.ErrRecordNotFound {
		return nil, result.Error
	}
	return history, result.Error
}
func (repo *LogStatusRepository) UpdateLogStatus(LogStatus *models.LogStatus) error {
	result := repo.db.Save(LogStatus)
	return result.Error
}
func (repo *LogStatusRepository) DeleteLogStatusByAddress(address string) error {
	// Delete records with the given address
	if err := repo.db.Where("address = ?", address).Delete(&models.LogStatus{}).Error; err != nil {
		return err
	}
	return nil
}
func (repo *LogStatusRepository) CheckExistsInLogStatus(address string) (bool, error) {
	var existingAddress *models.LogStatus
	if err := repo.db.Where("address = ?", address).First(&existingAddress).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			// Address does not exist
			return false, nil
		}
		// Other errors occurred
		return false, err
	}
	// Address exists
	return true, nil
}
func (repo *LogStatusRepository) CompareLastLogin(tenMinutesAgo uint) ([]*models.LogStatus, error) {
	//check in log_status table, if any address has current time - last_log_in > 10ph
	// Query records where last_log_in is more than ten minutes ago
	var recordsToDelete []*models.LogStatus
	if err := repo.db.Where("last_login < ?", tenMinutesAgo).Find(&recordsToDelete).Error; err != nil {
		return recordsToDelete, err
	}
	return recordsToDelete, nil
}

func (repo *LogStatusRepository) DeleteLogStatusBeforeMinutes(minutesAgo uint) error {
	// Delete records with the given address
	return repo.db.Where("last_login < ?", minutesAgo).Delete(&models.LogStatus{}).Error
}
