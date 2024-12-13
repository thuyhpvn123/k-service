package database

import (
	"log"

	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

func InitializeDB(connectionString string) error {
	var err error
	DB, err = gorm.Open(mysql.Open(connectionString), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	return err
}

func NewDBConnection(connectionString string) (*gorm.DB, error) {
	return gorm.Open(mysql.Open(connectionString), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
}

func Migrate() {
	err := DB.AutoMigrate(
		&models.BonusHistory{},
		&models.DiscountHistory{},
		&models.UserInfo{},
		&models.SubInfoHistory{},
		&models.EBuyProductDataHistory{},
		&models.LogHistory{},
		&models.LogStatus{},
	)
	if err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}
}

func CloseDB() {
	sqlDB, err := DB.DB()
	if err != nil {
		log.Printf("Failed to close database connection: %v", err)
	}
	sqlDB.Close()
}
