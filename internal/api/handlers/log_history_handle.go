package handlers

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/api/request"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/repositories"
	"github.com/meta-node-blockchain/meta-node/pkg/logger"

	// "gorm.io/driver/mysql"
	"errors"
)

type LogHistoryHandler struct {
	LogHistoryRepo       *repositories.LogRepository
	LogStatusHistoryRepo *repositories.LogStatusRepository
}

func NewLogHistoryHandler(
	LogHistoryRepo *repositories.LogRepository,
	LogStatusHistoryRepo *repositories.LogStatusRepository,
) *LogHistoryHandler {
	return &LogHistoryHandler{LogHistoryRepo: LogHistoryRepo, LogStatusHistoryRepo: LogStatusHistoryRepo}
}
func (h *LogHistoryHandler) LogIn(c *gin.Context) {
	var loginData request.LogInRequest
	err := c.ShouldBindJSON(&loginData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to bind query %v", err),
		})
		return
	}
	ifExist, err := h.LogStatusHistoryRepo.CheckExistsInLogStatus(loginData.Address)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to CheckExistsInLogStatus %v", err),
		})
		return
	}
	logIn := &models.LogHistory{
		Address:   loginData.Address,
		TimeLogIn: loginData.TimeLogIn,
	}
	//check if not have record in LogStatus then create an record in LogHistory first time
	if !ifExist {
		err = h.LogHistoryRepo.CreateLog(logIn)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": fmt.Sprintf("Unable to create log %v", err),
			})
			return
		}
	} else {
		//if there an record with same address in LogStatus then only update time_log_out
		err = h.UpdateTimeLogOut(loginData.Address, loginData.TimeLogIn)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": fmt.Sprintf("Fail to UpdateTimeLogOut %v", err),
			})
			return
		}
	}
	//create record in LogStatus
	logStatus := &models.LogStatus{
		Address:   loginData.Address,
		LastLogin: loginData.TimeLogIn,
	}
	err = h.LogStatusHistoryRepo.CreateLogStatus(logStatus)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to create log status %v", err),
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"message": "successful created login",
	})
}
func (h *LogHistoryHandler) UpdateLogOut(c *gin.Context) {
	var logoutData request.LogOutRequest
	err := c.ShouldBindJSON(&logoutData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to bind query %v", err),
		})
		return
	}
	err = h.UpdateTimeLogOut(logoutData.Address, logoutData.TimeLogOut)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Fail to UpdateTimeLogOut %v", err),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "successful updated logout",
	})
}
func (h *LogHistoryHandler) UpdateTimeLogOut(address string, timeLogOut uint) error {
	logData, err := h.LogHistoryRepo.GetLastLogByAddress(address)
	if err != nil {
		return err
	}
	currentTime := time.Now()
	if timeLogOut < logData.TimeLogIn || int64(timeLogOut) > currentTime.Unix() {
		return errors.New("Time Log wrong")
	}
	logData.TimeLogOut = timeLogOut
	logData.TimeUse = timeLogOut - logData.TimeLogIn
	err = h.LogHistoryRepo.UpdateLog(logData)
	if err != nil {
		return err
	}
	//delete record in log_status
	err = h.LogStatusHistoryRepo.DeleteLogStatusByAddress(address)
	if err != nil {
		logger.Error("error when DeleteLogStatusByAddress", err)
		return err
	}
	return nil
}
func (h *LogHistoryHandler) CheckLogoutEveryMinute() error {
	//check in log_status table, if any address has current time - last_log_in > 11ph
	// Query records where last_log_in is more than ten minutes ago
	err := h.LogStatusHistoryRepo.DeleteLogStatusBeforeMinutes(uint(time.Now().Add(-11 * time.Minute).Unix()))
	if err != nil {
		logger.Error("error when DeleteLogStatus", err)
		return err
	}
	return nil
}
