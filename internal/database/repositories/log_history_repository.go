package repositories

import (
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	"gorm.io/gorm"
    // "errors"
    "fmt"
)

type LogRepository struct {
	db *gorm.DB
}

func NewLogRepository(db *gorm.DB) *LogRepository {
	return &LogRepository{db}
}

func (repo *LogRepository) CreateLog(Log *models.LogHistory) error {
	return repo.db.Create(Log).Error
}

func (repo *LogRepository) GetLastLogByAddress(address string) (*models.LogHistory, error) {
	var history *models.LogHistory
	result := repo.db.Model(&models.LogHistory{}). Where("address LIKE ?", "%"+address+"%").Last(&history)
    if result.Error == gorm.ErrRecordNotFound {
        return nil, result.Error
    }
    return history, result.Error
}
//GetLogByAddressAndTime to get number of children from time to time
func (repo *LogRepository) GetLastLogByAddressAndTime(address string, from int, to int) (*models.LogHistory, error) {
    var history *models.LogHistory
    result := repo.db.Model(&models.LogHistory{}).
        Where("address LIKE ?", "%"+address+"%").
        Where("time >= ? AND time <=?", from, to).
        Last(&history)
    if result.Error == gorm.ErrRecordNotFound {
        return nil, result.Error
    }
    return history, result.Error
}
func (repo *LogRepository) UpdateLog(Log *models.LogHistory) error {
	result := repo.db.Save(Log)
	return result.Error
}
//CountTotalDistinctAddressesByTime to get total of distinct children array log in from time to time(active user)
func (repo *LogRepository)CountTotalDistinctAddressesByTime(addresses []string, from int, to int) ([]*models.LogHistory,int, error) {
    var histories []*models.LogHistory
    var totalCount int

    result := repo.db.Model(&models.LogHistory{}).
        Distinct("address").
        Where("address IN (?)", addresses).
        Where("time_log_in >= ? AND time_log_in <= ?", from, to).
        Find(&histories)
    if result.Error != nil {
        return histories,totalCount, result.Error
    }
    totalCount = len(histories)
    return histories,totalCount, nil
}
//CountTotalLoginOfChildrenByTime to get total of logins of children array from time to time(new login)
func (repo *LogRepository) CountTotalLoginOfChildrenByTime(addresses []string, from int, to int) ([]*models.LogHistory,int, error) {
    var histories []*models.LogHistory
    var totalCount int

    result := repo.db.Model(&models.LogHistory{}).
        Where("address IN (?)", addresses).
        Where("time_log_in >= ? AND time_log_in <= ?", from, to).
        Find(&histories)
    if result.Error != nil {
        return histories,totalCount, result.Error
    }
    totalCount = len(histories)
    return histories,totalCount, nil
}
// Query to calculate the average time use for addresses within the specified time range(used time)
func (repo *LogRepository) CountAverageTimeUseChildrenByTime(addresses []string, from int, to int) (float64, string) {
    var averageTimeUse *float64
    result := repo.db.Model(&models.LogHistory{}).
        Where("address IN (?)", addresses).
        Where("time_log_in >= ? AND time_log_in <= ?", from, to).
        Where("time_log_out <> 0").
        Select("AVG(time_use)").
        Row().
        Scan(&averageTimeUse)
    if result != nil {
        return 0, result.Error()
    }
    if averageTimeUse == nil {
        // Handle NULL value, for example return -1 as a placeholder
        return 0, ""
    }

    return *averageTimeUse, ""
}
func (repo *LogRepository) CalculateAverageMaxTimeDifference(addresses []string,current uint) (map[string]interface{}, error) {
    // Query to get the maximum log_time_in for each address in the input array
    var maxLogTimeIns []struct {
        Address       string `gorm:"column:address"`
        MaxLogTimeIn  uint    `gorm:"column:max_log_time_in"`
    }
    err := repo.db.Table("log_histories").
        Select("address, MAX(time_log_in) AS max_log_time_in").
        Where("address IN (?)", addresses).
        Group("address").
        Scan(&maxLogTimeIns).Error
    if err != nil {
        return nil, err
    }

    // Calculate the differences between the maximum log_time_in values
    differences := make(map[string]uint)
    for _, entry := range maxLogTimeIns {
        differences[entry.Address] = current - entry.MaxLogTimeIn
    }

    // Calculate the average of the maximum log_time_in values
    var sum uint
    for _, entry := range maxLogTimeIns {
        sum += uint(differences[entry.Address])
    }
    average := float64(sum) / float64(len(maxLogTimeIns))

    // Construct the result map
    result := make(map[string]interface{})
    for _, entry := range maxLogTimeIns {
        result[entry.Address] = differences[entry.Address]
    }
    result["average_max_log_time_in"] = fmt.Sprintf("%.f",average)

    return result, nil
}
func (repo *LogRepository) GetLastActivationTime(address string, current uint) (uint, error) {
    var history *models.LogHistory
    result := repo.db.Model(&models.LogHistory{}).
    Where("address = ?", address).
    Order("time_log_in DESC").
    Find(&history)
    if result.Error != nil {
        return 0, result.Error
    }
    difference := current - history.TimeLogIn

    return difference, nil
}
