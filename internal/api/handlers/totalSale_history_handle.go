package handlers

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/api/request"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/repositories"
	// "github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/services"
)

type EBuyProductDataHistoryHandler struct {
	EBuyProductDataHistoryRepo *repositories.EBuyProductDataRepository
	LogHistoryRepo *repositories.LogRepository
	SubInfoHistoryRepo *repositories.SubInfoRepository

}

func NewEBuyProductDataHistoryHandler(
	EBuyProductDataHistoryRepo *repositories.EBuyProductDataRepository,
	LogHistoryRepo *repositories.LogRepository,
	SubInfoHistoryRepo *repositories.SubInfoRepository,
	) *EBuyProductDataHistoryHandler {
	return &EBuyProductDataHistoryHandler{
		EBuyProductDataHistoryRepo: EBuyProductDataHistoryRepo,
		LogHistoryRepo: LogHistoryRepo,
		SubInfoHistoryRepo: SubInfoHistoryRepo,
	}
}
func (h *EBuyProductDataHistoryHandler) QueryActiveUser(c *gin.Context) {
	var queryData request.QueryEBuyHistoryByTimeRequest
	activeUserHistories := make(map[string]interface{})
	var result []map[string]interface{}

	err := c.ShouldBindQuery(&queryData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to bind query %v", err),
		})
		return
	}
	var childrenArr []string
	childrenArr,err =h.SubInfoHistoryRepo.GetAllSubInfoByLineAddress(queryData.Address)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable CallChildrenArr %v", err),
		})
		return
	}
	if len(childrenArr)>0 {
		//active user
		arr := EndOfDaysBetween(queryData.From,queryData.To)
		for i:=0;i< len(arr)-1;i++{
			// var totalAmount uint
			activeArr,activeUsers, err := h.LogHistoryRepo.CountTotalDistinctAddressesByTime(childrenArr,arr[i], arr[i+1])
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": fmt.Sprintf("Can't CountTotalDistinctAddressesByTime %v", err),
				})
				return
			}
			activeMap := make(map[string]interface{})
			for _,child := range activeArr {
				userData, err := h.SubInfoHistoryRepo.GetSubInfoByAddress(child.Address)
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": fmt.Sprintf("Can't get GetUserDataByAddress now %v", err),
					})
					return
				}
				// if(childRev >0){
					detail:= make(map[string]interface{})
					activeMap[child.Address]=detail	
					detail["name"] = userData.Name
					detail["phone"] = userData.Phone
					detail["from"] = arr[i]
					detail["to"] = arr[i+1]	
				// }

			}
			if(len(activeArr)>0){
				activeUserHistories = map[string]interface{}{
					"address":queryData.Address,
					"active-user": map[string]interface{}{
						"count":activeUsers,
						"add":activeMap,
					},			
				}
				result = append(result,activeUserHistories)
			}
		}
	}else{
		activeUserHistories = map[string]interface{}{
			"address":queryData.Address,
			"from":queryData.From,
			"to":queryData.To,
			"data":"no children",
		}
		result = append(result,activeUserHistories)
	}
	c.JSON(http.StatusOK, gin.H{
		"message": "successful request",
		"data":    result,
	})
	
}
func (h *EBuyProductDataHistoryHandler) QueryLastActivate(c *gin.Context) {
	var queryData request.QueryEBuyHistoryByTimeRequest
	LastActiveHistories := make(map[string]interface{})

	err := c.ShouldBindQuery(&queryData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to bind query %v", err),
		})
		return
	}
	var childrenArr []string
	childrenArr,err =h.SubInfoHistoryRepo.GetAllSubInfoByLineAddress(queryData.Address)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable CallChildrenArr %v", err),
		})
		return
	}
	if len(childrenArr)>0 {
		//Last Activation
		currentTime := uint(time.Now().Unix())
		_, err := h.LogHistoryRepo.CalculateAverageMaxTimeDifference(childrenArr,currentTime)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": fmt.Sprintf("Can't CalculateAverageMaxTimeDifference %v", err),
			})
			return
		}
		lastActivationMap := make(map[string]interface{})
		for _,child := range childrenArr{

			lastActChild ,err := h.LogHistoryRepo.GetLastActivationTime(child,currentTime)
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": fmt.Sprintf("Can't get GetLastActivationTime now %v", err),
				})
				return
			}
			userData, err := h.SubInfoHistoryRepo.GetSubInfoByAddress(child)
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": fmt.Sprintf("Can't get GetUserDataByAddress now %v", err),
				})
				return
			}
			detail := make(map[string]interface{})
			lastActivationMap[child]=detail

			detail["name"] = userData.Name
			detail["phone"] = userData.Phone
			detail["last-activate"] = lastActChild

		}

		LastActiveHistories = map[string]interface{}{
			"address":queryData.Address,
			"last-activation":lastActivationMap,
		}

	}else{
		LastActiveHistories = map[string]interface{}{
			"address":queryData.Address,
			"data":"no children",

		}
	}
	c.JSON(http.StatusOK, gin.H{
		"message": "successful request",
		"data":    LastActiveHistories,
	})
}
func (h *EBuyProductDataHistoryHandler) QueryNewLogin(c *gin.Context) {
	var result []map[string]interface{}
	var queryData request.QueryEBuyHistoryByTimeRequest
	newLoginHistories := make(map[string]interface{})

	err := c.ShouldBindQuery(&queryData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to bind query %v", err),
		})
		return
	}
	var childrenArr []string
	childrenArr,err =h.SubInfoHistoryRepo.GetAllSubInfoByLineAddress(queryData.Address)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable CallChildrenArr %v", err),
		})
		return
	}
	if len(childrenArr)>0 {
		//new login		
		arr := EndOfDaysBetween(queryData.From,queryData.To)
		for i:=0;i< len(arr)-1;i++{
			var totalAmount uint
			newloginArr,newlogin, err := h.LogHistoryRepo.CountTotalLoginOfChildrenByTime(childrenArr,arr[i], arr[i+1])
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": fmt.Sprintf("Can't CountTotalLoginOfChildrenByTime %v", err),
				})
				return
			}
			newLoginMap := make(map[string]interface{})
			for _,child := range newloginArr {
				detail := make(map[string]interface{})
				newLoginMap[child.Address] = detail
				userData, err := h.SubInfoHistoryRepo.GetSubInfoByAddress(child.Address)
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": fmt.Sprintf("Can't get GetUserDataByAddress now %v", err),
					})
					return
				}
				childArr := []string{child.Address}
				newloginArr,newloginchild, err := h.LogHistoryRepo.CountTotalLoginOfChildrenByTime(childArr,arr[i], arr[i+1])
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": fmt.Sprintf("Can't CountTotalLoginOfChildrenByTime %v", err),
					})
					return
				}
				totalAmount += uint(newloginchild)
				if(newloginchild>0){
					detail["count_child"]=newloginchild
					detail["name"] = userData.Name
					detail["phone"] = userData.Phone
					detail["detail"]=newloginArr
					detail["from"] = arr[i]
					detail["to"] = arr[i+1]	
				}
			}
			if(totalAmount>0){
				newLoginHistories = map[string]interface{}{
					"address":queryData.Address,
					"from":queryData.From,
					"to":queryData.To,
					"new-login":map[string]interface{}{
						"count":newlogin,
						"add":newLoginMap,
					},
				}	
				result = append(result,newLoginHistories)

			}
	
		}
	}else{
		newLoginHistories = map[string]interface{}{
			"address":queryData.Address,
			"from":queryData.From,
			"to":queryData.To,
			"data":"no children",

		}
		result = append(result,newLoginHistories)

	}
	c.JSON(http.StatusOK, gin.H{
		"message": "successful request",
		"data":    result,
	})
}
func (h *EBuyProductDataHistoryHandler) QueryTotalRevenue(c *gin.Context) {
	var result []map[string]interface{}
	var queryData request.QueryEBuyHistoryByTimeRequest
	totalSaleHistories := make(map[string]interface{})

	err := c.ShouldBindQuery(&queryData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to bind query %v", err),
		})
		return
	}
	var childrenArr []string
	childrenArr,err =h.SubInfoHistoryRepo.GetAllSubInfoByLineAddress(queryData.Address)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable CallChildrenArr %v", err),
		})
		return
	}	
	if len(childrenArr)>0 {
		//total revenue
		arr := EndOfDaysBetween(queryData.From,queryData.To)
		fmt.Println("array la:",arr)
		for i:=0;i< len(arr)-1;i++{

			fmt.Println("from la:",arr[i])
			fmt.Println("to la:",arr[i+1])
			fmt.Println("i la:",i)

			var totalAmount uint
			userMap := make(map[string]interface{})
			for _,child := range childrenArr {
				
				var histories []*models.EBuyProductDataHistory
				histories, err = h.EBuyProductDataHistoryRepo.GetEBuyProductDataByAddressAndTime(child,arr[i], arr[i+1])
		
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": fmt.Sprintf("Can't get EBuyProductDataHistory now %v", err),
					})
					return
				}
				var childRev uint
				for _,v := range histories {
					totalAmount += v.TotalPrice 
					childRev += v.TotalPrice
				}
				//get name, phone	
				userData, err := h.SubInfoHistoryRepo.GetSubInfoByAddress(child)
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": fmt.Sprintf("Can't get GetUserDataByAddress now %v", err),
					})
					return
				}
				if(childRev >0){
					fmt.Println("child la:",child)
					detail := make(map[string]interface{})
					userMap[child]= detail
					detail["name"] = userData.Name
					detail["phone"] = userData.Phone
					detail["revenue"] = childRev
					detail["from"] = arr[i]
					detail["to"] = arr[i+1]	
				}
			}
			if(totalAmount>0){
				fmt.Println("each child:",userMap)
				totalSaleHistories = map[string]interface{}{
					"address":queryData.Address,
					"totalSale":map[string]interface{}{
						"totalAmount":totalAmount,
						"eachChild":userMap,
					},
				}
				result = append(result,totalSaleHistories)

			}	
		}
	}else{
		totalSaleHistories = map[string]interface{}{
			"address":queryData.Address,
			"from":queryData.From,
			"to":queryData.To,
			"data":"no children",
		}
		result = append(result,totalSaleHistories)

	}
	c.JSON(http.StatusOK, gin.H{
		"message": "successful request",
		"data":    result,
	})

}
func (h *EBuyProductDataHistoryHandler) QueryUsedTime(c *gin.Context) {
	var result []map[string]interface{}
	var queryData request.QueryEBuyHistoryByTimeRequest
	UsedTimeHistories := make(map[string]interface{})

	err := c.ShouldBindQuery(&queryData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to bind query %v", err),
		})
		return
	}
	var childrenArr []string
	childrenArr,err =h.SubInfoHistoryRepo.GetAllSubInfoByLineAddress(queryData.Address)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable CallChildrenArr %v", err),
		})
		return
	}
	if len(childrenArr)>0 {
		//used time	
		arr := EndOfDaysBetween(queryData.From,queryData.To)
		fmt.Println("array:",arr)
		for i:=0;i< len(arr)-1;i++{	
			var totalAmount float64
			usedTime, error := h.LogHistoryRepo.CountAverageTimeUseChildrenByTime(childrenArr,arr[i], arr[i+1])
			if error != "" {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": fmt.Sprintf("Can't CountAverageTimeUseChildrenByTime %v", error),
				})
				return
			}
			userMap := make(map[string]interface{})
			for _,v := range childrenArr {
	
				child := make([]string,1)
				child = append(child,v)
				usedTimeChild, error := h.LogHistoryRepo.CountAverageTimeUseChildrenByTime(child,arr[i], arr[i+1])
				if error != "" {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": fmt.Sprintf("Can't CountAverageTimeUseChildrenByTime Child %v", error),
					})
					return
				}
				totalAmount += usedTimeChild 
				//get name, phone	
				userData, err := h.SubInfoHistoryRepo.GetSubInfoByAddress(v)
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": fmt.Sprintf("Can't get GetUserDataByAddress now %v", err),
					})
					return
				}
				if usedTimeChild >0 {
					fmt.Println("child la",v)
					detail := make(map[string]interface{})
					userMap[v]= detail	
					detail["used-time"] = usedTimeChild
					detail["name"] = userData.Name
					detail["phone"] = userData.Phone	
					detail["from"] = arr[i]
					detail["to"] = arr[i+1]	
				}
			}
			if(totalAmount>0){
				UsedTimeHistories = map[string]interface{}{
					"address":queryData.Address,
					// "from":queryData.From,
					// "to":queryData.To,
					"used-time":map[string]interface{}{
						"children":usedTime,
						"eachChild":userMap,
					},
				}
				result = append(result,UsedTimeHistories)
	
			}
	
	
		}
	}else{
		UsedTimeHistories = map[string]interface{}{
			"address":queryData.Address,
			"from":queryData.From,
			"to":queryData.To,
			"data":"no children",
		}
		result = append(result,UsedTimeHistories)

	}
	c.JSON(http.StatusOK, gin.H{
		"message": "successful request",
		"data":    result,
	})
	
}

func EndOfDaysBetween(start, end int) []int {
    // Convert the input timestamps to time.Time
    startTime := time.Unix(int64(start), 0)
    endTime := time.Unix(int64(end), 0)

    // Initialize an empty array to store the end of each day
    var endOfDays []int64

    // Add the start time to the array
    endOfDays = append(endOfDays, startTime.Unix())

    // Start from the beginning of the first day after the start time
    current := time.Date(startTime.Year(), startTime.Month(), startTime.Day(), 0, 0, 0, 0, startTime.Location()).Add(24 * time.Hour)

    // Iterate until we reach the end time
    for current.Before(endTime) {
        // Add the end of the current day to the array
        endOfDays = append(endOfDays, current.Add(-time.Second).Unix())

        // Move to the next day
        current = current.Add(24 * time.Hour)
    }

    // Add the end time to the array if it's not already included
    if endOfDays[len(endOfDays)-1] != endTime.Unix() {
        endOfDays = append(endOfDays, endTime.Unix())
    }
	intArray := make([]int, len(endOfDays))
    for i, v := range endOfDays {
        intArray[i] = int(v)
    }

    return intArray
}