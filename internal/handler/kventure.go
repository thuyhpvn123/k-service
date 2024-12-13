package handler

import (
	"encoding/hex"
	"encoding/json"
	"fmt"
	"math/big"
	"slices"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"

	e_common "github.com/ethereum/go-ethereum/common"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/repositories"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/services"
	"github.com/meta-node-blockchain/meta-node/pkg/logger"
	"github.com/meta-node-blockchain/meta-node/types"
)

type KventureHandler struct {
	retailSCAddress e_common.Address
	kventureSCAbi   *abi.ABI
	productSCAbi    *abi.ABI
	retailSCAbi     *abi.ABI
	repos           *repositories.Repositories
	eBonusHash      string
	KvenSubHash     string
	eBuyProductHash string
	eDiscountLink   string
	teleServ        *services.TeleService
}

func NewKventureHandler(
	retailSCAddress e_common.Address,
	kventureSCAbi *abi.ABI,
	productSCAbi *abi.ABI,
	retailSCAbi *abi.ABI,
	repos *repositories.Repositories,
	eBonusHash string,
	KvenSubHash string,
	eBuyProductHash string,
	eDiscountLink string,
	teleServ *services.TeleService,
) *KventureHandler {
	return &KventureHandler{
		retailSCAddress: retailSCAddress,
		kventureSCAbi:   kventureSCAbi,
		productSCAbi:    productSCAbi,
		retailSCAbi:     retailSCAbi,
		repos:           repos,
		eBonusHash:      eBonusHash,
		KvenSubHash:     KvenSubHash,
		eBuyProductHash: eBuyProductHash,
		eDiscountLink:   eDiscountLink,
		teleServ:        teleServ,
	}
}

var TypeRegisterBonus = []string{"Matrix", "Direct", "Matching"}

func (h *KventureHandler) HandleEvent(
	events types.EventLogs,
) {
	for _, v := range events.EventLogList() {
		switch v.Topics()[0] {
		case h.eBonusHash:
			{
				eventResult := make(map[string]interface{})
				err := h.kventureSCAbi.UnpackIntoMap(eventResult, "PayBonus", e_common.FromHex(v.Data()))
				if err != nil {
					logger.Error("error when unpack into map")
					continue
				}
				typ := eventResult["typ"].(string)
				add := eventResult["add"].(common.Address)
				time := uint(eventResult["time"].(*big.Int).Uint64())
				amount := eventResult["commission"].(*big.Int).Uint64()

				bonusHistory := &models.BonusHistory{
					Address:         add.String(),
					Type:            typ,
					Time:            time,
					Amount:          amount,
					Rank:            uint(eventResult["rank"].(*big.Int).Uint64()),
					Index:           uint(eventResult["index"].(*big.Int).Uint64()),
					Rate:            uint(eventResult["rate"].(*big.Int).Uint64()),
					BlockCount:      v.BlockNumber(),
					TransactionHash: v.TransactionHash(),
					LogHash:         v.Hash().Hex(),
				}
				h.repos.BonusHistory.CreateBonusHistory(bonusHistory)
				if !slices.Contains(TypeRegisterBonus, typ) {
					h.teleServ.SendBonusNoti(bonusHistory)
				}
			}
		case h.kventureSCAbi.Events["Subcribed"].ID.String()[2:]:
			{
				eventResult := make(map[string]interface{})
				err := h.kventureSCAbi.UnpackIntoMap(eventResult, "Subcribed", e_common.FromHex(v.Data()))
				if err != nil {
					logger.Error("error when unpack into map")
					continue
				}

				subInfo := models.SubInfo{
					Address:      eventResult["subcriber"].(common.Address).Hex(),
					Amount:       eventResult["amount"].(*big.Int),
					ParentDirect: eventResult["parentDirect"].(common.Address).Hex(),
					ParentMatrix: eventResult["parentMatrix"].(common.Address).Hex(),
					Time:         uint(eventResult["time"].(*big.Int).Uint64()),
				}

				h.teleServ.SendSubNoti(&subInfo)
				phoneValue, ok := eventResult["phone"].([32]uint8)
				var phone string
				if ok {
					// If the value is a byte array, convert it to a string
					phone = hex.EncodeToString(phoneValue[:])
					// Now you can use the 'phone' variable as a string
				} else {
					// Handle the case where the value is not a byte array
					logger.Error("error phone not a byte array")
					continue
				}
				subInfoHis := models.SubInfoHistory{
					Address:      eventResult["subcriber"].(common.Address).Hex(),
					ParentDirect: eventResult["parentDirect"].(common.Address).Hex(),
					ParentMatrix: eventResult["parentMatrix"].(common.Address).Hex(),
					Time:         uint(eventResult["time"].(*big.Int).Uint64()),
					Phone:        phone,
				}
				h.repos.SubInfoHistory.CreateSubInfo(&subInfoHis)

			}

		case h.eBuyProductHash:
			{
				eventResult := make(map[string]interface{})
				err := h.productSCAbi.UnpackIntoMap(eventResult, "eBuyProduct", e_common.FromHex(v.Data()))
				if err != nil {
					logger.Error("error when unpack into map")
					continue
				}

				jsonData, err := json.Marshal(eventResult)
				if err != nil {
					logger.Error("json.Marshal(eventResult)")
					return
				}
				fmt.Println("eventResult:", eventResult)
				eBuyProductData := &models.EBuyProductData{}

				err = json.Unmarshal([]byte(jsonData), eBuyProductData)
				if err != nil {
					logger.Error("json.Unmarshal([]byte(jsonData), &eBuyProductData)", eBuyProductData)
					return
				}
				if h.retailSCAddress.Hex() == v.Address().Hex() {
					h.teleServ.SendBuyProductNoti(eBuyProductData, "PO5 Retail")
				} else {
					h.teleServ.SendBuyProductNoti(eBuyProductData, "PO5")
				}
				eBuyProductDataHis := models.EBuyProductDataHistory{
					Add:        eventResult["add"].(common.Address).Hex(),
					TotalPrice: uint(eventResult["totalPrice"].(*big.Int).Uint64()),
					Time:       uint(eventResult["time"].(*big.Int).Uint64()),
				}
				h.repos.EBuyProductDataHistory.CreateEBuyProductData(&eBuyProductDataHis)
				sub, err := h.repos.SubInfoHistory.GetSubInfoByAddress(eventResult["add"].(common.Address).String())
				if err != nil {
					logger.Error("error when GetSubInfoByAddress")
					continue
				}
				// newSub := &models.SubInfoHistory{
				// 	Address:      sub.Address,
				// 	ParentDirect: sub.ParentDirect,
				// 	ParentMatrix: sub.ParentMatrix,
				// 	Time:         sub.Time,
				// 	Rankq:		  sub.Rankq,
				// 	IsActive:	  sub.IsActive,
				// 	Phone: 		  sub.Phone,
				// 	Name: 		  sub.Name,
				// 	TotalBuyCode: sub.TotalBuyCode + eBuyProductDataHis.TotalPrice,
				// }
				newTotalBuyCode := sub.TotalBuyCode + eBuyProductDataHis.TotalPrice
				sub.TotalBuyCode = newTotalBuyCode
				err = h.repos.SubInfoHistory.UpdateSubInfo(sub)
				if err != nil {
					logger.Error("error when UpdateSubInfo")
					continue
				}
			}

		case h.eDiscountLink:
			eventResult := make(map[string]interface{})
			err := h.retailSCAbi.UnpackIntoMap(eventResult, "eDiscountLink", e_common.FromHex(v.Data()))
			if err != nil {
				logger.Error("error when unpack into map")
				continue
			}

			history := &models.DiscountHistory{
				Address:  eventResult["add"].(common.Address).String(),
				Percent:  uint(eventResult["percent"].(*big.Int).Uint64()),
				Time:     uint(eventResult["time"].(*big.Int).Uint64()),
				Discount: uint(eventResult["totalDiscount"].(*big.Int).Uint64()),
				Link:     eventResult["link"].(common.Address).String(),
			}

			h.repos.DiscountHistory.CreateDiscountHistory(history)
		case h.kventureSCAbi.Events["UserData"].ID.String()[2:]:
			eventResult := make(map[string]interface{})
			err := h.kventureSCAbi.UnpackIntoMap(eventResult, "UserData", e_common.FromHex(v.Data()))
			if err != nil {
				logger.Error("error when unpack into map")
				continue
			}
			sub, err := h.repos.SubInfoHistory.GetSubInfoByAddress(eventResult["add"].(common.Address).String())
			if err != nil {
				logger.Error("error when GetSubInfoByAddress")
				continue
			}

			phoneValue, ok := eventResult["phone"].([]uint8)
			var phone string
			if ok {
				// If the value is a byte array, convert it to a string
				phone = hex.EncodeToString(phoneValue[:])
				// Now you can use the 'phone' variable as a string
			} else {
				// Handle the case where the value is not a byte array
				logger.Error("error phone not a byte array")
				continue
			}
			if eventResult["name"].(string) == "" {
				//update phone
				sub.Phone = phone
				err = h.repos.SubInfoHistory.UpdateSubInfo(sub)
				if err != nil {
					logger.Error("error when UpdateSubInfo")
					continue
				}
			} else {
				//update name
				sub.Name = eventResult["name"].(string)
				err = h.repos.SubInfoHistory.UpdateSubInfo(sub)
				if err != nil {
					logger.Error("error when UpdateSubInfo")
					continue
				}
			}
		case h.kventureSCAbi.Events["TeamData"].ID.String()[2:]:
			eventResult := make(map[string]interface{})
			err := h.kventureSCAbi.UnpackIntoMap(eventResult, "TeamData", e_common.FromHex(v.Data()))
			if err != nil {
				logger.Error("error when unpack into map")
				continue
			}
			sub, err := h.repos.SubInfoHistory.GetSubInfoByAddress(eventResult["add"].(common.Address).String())
			if err != nil {
				logger.Error("error when GetSubInfoByAddress")
				continue
			}

			if eventResult["IsActive"].(*big.Int).Uint64() == 2 {
				//update rank, IsActive only 0 or 1
				sub.Rankq = uint(eventResult["rank"].(*big.Int).Uint64())
				err = h.repos.SubInfoHistory.UpdateSubInfo(sub)
				if err != nil {
					logger.Error("error when UpdateSubInfo")
					continue
				}
			} else {
				//update IsActive
				sub.IsActive = uint(eventResult["IsActive"].(*big.Int).Uint64())
				err = h.repos.SubInfoHistory.UpdateSubInfo(sub)
				if err != nil {
					logger.Error("error when UpdateSubInfo")
					continue
				}
			}
		default:
			continue
		}
	}
}
