package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	// "github.com/meta-node-blockchain/meta-node/cmd/client/cmd/cli/command"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/api/request"
	// "github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/repositories"
)

type SubInfoHistoryHandler struct {
	SubInfoHistoryRepo *repositories.SubInfoRepository
	EBuyProductDataHistoryRepo *repositories.EBuyProductDataRepository
}

func NewSubInfoHistoryHandler(
	SubInfoHistoryRepo *repositories.SubInfoRepository,
	EBuyProductDataHistoryRepo *repositories.EBuyProductDataRepository,
	) *SubInfoHistoryHandler {
	return &SubInfoHistoryHandler{
		SubInfoHistoryRepo: SubInfoHistoryRepo,
		EBuyProductDataHistoryRepo: EBuyProductDataHistoryRepo,
	}
}
func (h *SubInfoHistoryHandler)GetMapNewUser(address string, from int, to int)(map[string]interface{},error){
	detail:= make(map[string]interface{})
	data := make(map[string]interface{})
	mapChild := make(map[string]interface{})
	newUsers,count, err := h.SubInfoHistoryRepo.GetSubInfoByLineAddressAndTime(address,from, to)
	if err != nil {
		return detail, err
	}
	userMap := make(map[string]interface{})
	for _,child := range newUsers {
		userMap[child]= detail
		userData, err := h.SubInfoHistoryRepo.GetSubInfoByAddress(child)
		if err != nil {
			return userMap, err
		}
		newUsersChild,_, err := h.SubInfoHistoryRepo.GetSubInfoByLineAddressAndTime(child,from, to)
		if err != nil {
			return detail, err
		}
		detailChild:= make(map[string]interface{})
		for _,v := range newUsersChild {
			mapChild[child]= detailChild
			userDataChild, err := h.SubInfoHistoryRepo.GetSubInfoByAddress(v)
			if err != nil {
				return userMap, err
			}
			detailChild["name"] = userDataChild.Name
			detailChild["phone"] = userDataChild.Phone
		}
		detail["child"] = mapChild
		detail["name"] = userData.Name
		detail["phone"] = userData.Phone
	}
	if count >0 {		
		data = map[string]interface{}{
			"address":address,
			"new-user":map[string]interface{}{
				"total":count,
				"add":userMap,
			},
			"from": from,
			"to": to,
		}
	
	}else{
		data = map[string]interface{}{
			"address":address,
			"data":"no new user",
			"from": from,
			"to": to,
		}
	}
	return data, nil

}
// func (h *SubInfoHistoryHandler)GetMap(inputArr []string)(map[string]interface{},error){

// 	detail:= make(map[string]interface{})
// 	userMap := make(map[string]interface{})
// 	for _,child := range inputArr {
// 		userMap[child]= detail
// 		userData, err := h.SubInfoHistoryRepo.GetSubInfoByAddress(child)
// 		if err != nil {
// 			return userMap, err
// 		}
// 		detail["name"] = userData.Name
// 		detail["phone"] = userData.Phone
// 	}
	
// 	return userMap, nil

// }
func (h *SubInfoHistoryHandler) QueryNewUser(c *gin.Context) {
	var queryData request.QuerySubInfoHistoryByTimeRequest
	data := make(map[string]interface{})
	err := c.ShouldBindQuery(&queryData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to bind query %v", err),
		})
		return
	}
	//new user
	data, err = h.GetMapNewUser(queryData.Address,queryData.From, queryData.To)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Can't GetSubInfoByLineAddressAndTime %v", err),
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"message": "successful request",
		"data":    data,
	})
}
func (h *SubInfoHistoryHandler) QueryNumberOfPurchase(c *gin.Context) {
	var queryData request.QuerySubInfoHistoryByTimeRequest
	data := make(map[string]interface{})
	var result []map[string]interface{}

	err := c.ShouldBindQuery(&queryData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to bind query %v", err),
		})
		return
	}
	//new user
	newUsers,count, err := h.SubInfoHistoryRepo.GetSubInfoByLineAddressAndTime(queryData.Address,queryData.From, queryData.To)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Can't GetSubInfoByLineAddressAndTime %v", err),
		})
		return
	}
	if count>0 {
		//total revenue
		arr := EndOfDaysBetween(queryData.From,queryData.To)
		for i:=0;i< len(arr)-1;i++{
			// var totalAmount uint
			//number of purchase
			userMap := make(map[string]interface{})
			for _,child := range newUsers {

				numOfPu, err := h.SubInfoHistoryRepo.GetTotalTimesBuyNewUserByTime(child,arr[i], arr[i+1])
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": fmt.Sprintf("Can't get GetSubInfoBuy now %v", err),
					})
					return
				}
				userData, err := h.SubInfoHistoryRepo.GetSubInfoByAddress(child)
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": fmt.Sprintf("Can't get GetSubInfoByAddress number of purchase %v", err),
					})
					return
				}
				ordersChild, err := h.EBuyProductDataHistoryRepo.GetEBuyProductDataByAddressAndTime(child,arr[i], arr[i+1])
				if err != nil {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": fmt.Sprintf("Can't get GetSubInfoBuy now %v", err),
					})
					return
				}
				if(len(ordersChild)>0){
					detail:= make(map[string]interface{})
					userMap[child]= detail
					detail["order-detail"]=ordersChild
					detail["name"] = userData.Name
					detail["phone"] = userData.Phone
			
				}
				data = map[string]interface{}{
					"address":queryData.Address,
					"number-of-purchase":map[string]interface{}{
						"total":numOfPu,
						"orders":userMap,
					},
					"from": queryData.From,
					"to": queryData.To,
				}
				result = append(result,data)
	
			}		

		}
	}else{
		data = map[string]interface{}{
			"address":queryData.Address,
			"data":"no new user",
			"from": queryData.From,
			"to": queryData.To,
		}
		result = append(result,data)	
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "successful request",
		"data":    data,
	})
}
func (h *SubInfoHistoryHandler) QueryConversion(c *gin.Context) {
	var queryData request.QuerySubInfoHistoryByTimeRequest

	err := c.ShouldBindQuery(&queryData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to bind query %v", err),
		})
		return
	}
	//new user
	_,count, err := h.SubInfoHistoryRepo.GetSubInfoByLineAddressAndTime(queryData.Address,queryData.From, queryData.To)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Can't GetSubInfoByLineAddressAndTime %v", err),
		})
		return
	}
	//conversion
	countBuy, err := h.SubInfoHistoryRepo.GetSubInfoBuy(queryData.Address,queryData.From, queryData.To)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Can't get GetSubInfoBuy now %v", err),
		})
		return
	}
	data := make(map[string]interface{})
	var conversion float64
	if count >0 {
		
		conversion = float64(countBuy)*100/float64(count) 
		data = map[string]interface{}{
			"address":queryData.Address,
			"coversion":fmt.Sprintf("%.2f", conversion),
			"from": queryData.From,
			"to": queryData.To,
		}
	
	}else{
		data = map[string]interface{}{
			"address":queryData.Address,
			"data":"no new user",
			"from": queryData.From,
			"to": queryData.To,
		}
	}
	c.JSON(http.StatusOK, gin.H{
		"message": "successful request",
		"data":    data,
	})
}
func (h *SubInfoHistoryHandler) QueryTeamFilter(c *gin.Context) {
	var queryData request.QuerySubInfoHistoryByFilter
	if err := c.ShouldBindJSON(&queryData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "bad request"})
		return
	}
	jBody, err := json.Marshal(queryData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"err": err.Error(),
		})
		return
	}
	filterData := make(map[string]interface{})
	err = json.Unmarshal(jBody, &filterData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"err": err.Error(),
		})
		return
	}
	fmt.Println("filterData:",filterData)

	careers, err := h.SubInfoHistoryRepo.GetManyWithFilter(filterData["parent_direct"].(string),filterData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"errors": "internal server errors"})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    careers,
	})
}


