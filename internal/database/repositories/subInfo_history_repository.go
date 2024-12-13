package repositories

import (
	// "strconv"
	// "strings"
	"fmt"

	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	"github.com/meta-node-blockchain/meta-node/pkg/logger"

	// "github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/utils"
	"gorm.io/gorm"
)

type SubInfoRepository struct {
	db *gorm.DB
}

func NewSubInfoRepository(db *gorm.DB) *SubInfoRepository {
	return &SubInfoRepository{db}
}

func (repo *SubInfoRepository) CreateSubInfo(SubInfo *models.SubInfoHistory) error {
	return repo.db.Create(SubInfo).Error
}
// func (repo *SubInfoRepository) UpdateSubInfo(SubInfo *models.SubInfoHistory) error {
// 	result := repo.db.Save(SubInfo)
// 	return result.Error
// }
func (repo *SubInfoRepository) UpdateSubInfo(SubInfo *models.SubInfoHistory) error {
	result := repo.db.Save(SubInfo)
	return result.Error
}
func (repo *SubInfoRepository) GetSubInfoByAddress(address string) (*models.SubInfoHistory, error) {
    var history *models.SubInfoHistory
	result := repo.db.Model(&models.SubInfoHistory{}).Where("address = ?", address).Find(&history)
	if result.Error != nil {
        return history, result.Error
    }
    return history, nil
}
func (repo *SubInfoRepository) GetCountSubInfoByLineAddress(address string) (int64, error) {
	var count int64
	result := repo.db.Model(&models.SubInfoHistory{}).Where("parent_direct = ?", address).Count(&count)
	if result.Error != nil {
        return count, result.Error
    }
    return count, nil
}
//GetSubInfoByLineAddressAndTime to get number of children from time to time
func (repo *SubInfoRepository) GetAllSubInfoByLineAddress(address string) ([]string, error) {
    var histories []*models.SubInfoHistory
    var historiesAdd [] string
    result := repo.db.Model(&models.SubInfoHistory{}).
        Where("parent_direct LIKE ?", "%"+address+"%").
        Find(&histories)
    if result.Error != nil {
        return historiesAdd, result.Error
    }
    for _,v := range histories {
        historiesAdd = append(historiesAdd,v.Address)
    }
    return historiesAdd, nil
}
//GetSubInfoByLineAddressAndTime to get number of children from time to time
func (repo *SubInfoRepository) GetSubInfoByLineAddressAndTime(address string, from int, to int) ([]string,int, error) {
    var histories []*models.SubInfoHistory
    var historiesAdd [] string
    var count int
    result := repo.db.Model(&models.SubInfoHistory{}).
        Where("parent_direct LIKE ?", "%"+address+"%").
        Where("time >= ? AND time <=?", from, to).
        Find(&histories)
    if result.Error != nil {
        return historiesAdd,count, result.Error
    }
    for _,v := range histories {
        historiesAdd = append(historiesAdd,v.Address)
    }
    count = len(histories)
    return historiesAdd,count, nil
}
//GetSubInfoBuy to get number of children of input that buy product from time to time
func (repo *SubInfoRepository) GetSubInfoBuy(address string, from int, to int) (int64, error) {
    var count int64
    var histories = []*models.SubInfoHistory{}
  
    result := repo.db.Model(&models.SubInfoHistory{}).
    Where("parent_direct LIKE ?", "%"+address+"%").
    Where("sub_info_histories.time >= ? AND sub_info_histories.time <= ?", from, to).
    Joins("INNER JOIN (SELECT DISTINCT e_buy_product_data_histories.add FROM e_buy_product_data_histories) AS e ON e.add = sub_info_histories.address").
    Find(&histories) 
    if result.Error != nil {
        return 0, result.Error
    }
    count = int64(len(histories))
    return count, nil
}
func (repo *SubInfoRepository) GetTotalTimesBuyNewUserByTime(address string, from int, to int) (int64, error) {
    var count int64  
    result := repo.db.Model(&models.SubInfoHistory{}).
    Where("parent_direct LIKE ?", "%"+address+"%").
    Where("sub_info_histories.time >= ? AND sub_info_histories.time <= ?", from, to).
    Joins("INNER JOIN e_buy_product_data_histories AS e ON e.add = sub_info_histories.address").
    Count(&count) 
    if result.Error != nil {
        return count, result.Error
    }
    return count, nil
}

func (repo *SubInfoRepository) GetManyWithFilter( address string,filterCriteria map[string]interface{}) ([]*models.SubInfoHistory, error) {
    var histories = []*models.SubInfoHistory{}
    // Split the parameter string by commas to get individual ranks
    fmt.Println("filterCriteria:",filterCriteria)

    ranksin, ok := filterCriteria["rankq"].([]interface{})
    if !ok{
        // Handle the case where the value is not a byte array
        logger.Error("error parse filterCriteria rank ")
    }
    ranks := make([]uint, len(ranksin))
	for i, v := range ranksin {
        ranks[i] = uint(v.(float64))
	}
    statusesin, ok := filterCriteria["status"].([]interface{})
    if !ok{
        logger.Error("error parse filterCriteria status")
    }
    statuses := make([]uint, len(statusesin))
	for i, v := range statusesin {
        statuses[i] = uint(v.(float64))
	}
    buyCode := filterCriteria["buy_code"].(string)
    minAmount := uint(filterCriteria["min_amount"].(float64))
    maxAmount := uint(filterCriteria["max_amount"].(float64))
	dbCondition := repo.db.Model(&models.SubInfoHistory{}).
    Where("parent_direct LIKE ?", "%"+address+"%").
    Where("rankq IN (?)",ranks).
    Where("is_active IN (?)", statuses).
    Where("total_buy_code >= ? AND total_buy_code <= ?",minAmount, maxAmount)
    if buyCode == "true" {
        dbCondition =   dbCondition.Joins("INNER JOIN (SELECT DISTINCT e_buy_product_data_histories.add FROM e_buy_product_data_histories) AS e ON e.add = sub_info_histories.address")
                        
    }

	result := dbCondition.Find(&histories)
	if result.Error != nil {
		return histories, result.Error
	}

	return histories, nil
}