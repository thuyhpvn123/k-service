package services

import (
	"bytes"
	"fmt"
	"math/big"
	"net/http"
	"strconv"
	"time"

	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/utils"
	"github.com/meta-node-blockchain/meta-node/pkg/logger"
)

type TeleService struct {
	chatID   string
	botToken string
}

func NewTeleService(chatId string, botToken string) *TeleService {
	return &TeleService{
		chatID:   chatId,
		botToken: botToken,
	}
}

func (s *TeleService) SendNoti(msg []byte) error {
	jsonStr := []byte(
		fmt.Sprintf(`{"chat_id": "%v", "text": "%v"}`, s.chatID, string(msg)),
	)
	resp, err := http.Post(
		fmt.Sprintf("https://api.telegram.org/bot%s/sendMessage", s.botToken),
		"application/json",
		bytes.NewBuffer(jsonStr),
	)
	if err != nil {
		logger.Debug("resp ", resp)
		return err
	}
	defer resp.Body.Close()
	return nil
}

func (s *TeleService) SendSubNoti(subInfo *models.SubInfo) error {
	humanTime := time.Unix(int64(subInfo.Time), 0).Format("2006-01-02 15:04:05")
	normalAmount := new(big.Int).Div(subInfo.Amount, big.NewInt(1000000)).String()
	var buffer bytes.Buffer
	buffer.WriteString("📣📣📣[Sub Noti - PO5]📣📣📣\n")
	buffer.WriteString(fmt.Sprintf("📌 Address: %s\n", subInfo.Address))
	buffer.WriteString(fmt.Sprintf("📌 Amount: %s\n", normalAmount))
	buffer.WriteString(fmt.Sprintf("📌 Register Time: %s\n", humanTime))
	buffer.WriteString(fmt.Sprintf("📌 Line: %s\n", subInfo.ParentDirect))
	buffer.WriteString(fmt.Sprintf("📌 Line Matrix: %s\n", subInfo.ParentMatrix))
	return s.SendNoti(buffer.Bytes())
}

func (s *TeleService) SendBonusNoti(bonusHistory *models.BonusHistory) error {
	var buffer bytes.Buffer
	sRank := ""
	switch bonusHistory.Rank {
	case 0:
		sRank = "Unranked"
	case 1:
		sRank = "Bronze"
	case 2:
		sRank = "Silver"
	case 3:
		sRank = "Gold"
	case 4:
		sRank = "Platinum"
	case 5:
		sRank = "Diamond"
	case 6:
		sRank = "CrownDiamond"
	}

	sF := "F"

	switch bonusHistory.Type {
	case "Sale":
		buffer.WriteString("📣📣📣[HH bán hàng]📣📣📣\n")
		if bonusHistory.Index == 0 {
			sF += "a"
		} else {
			sF += strconv.Itoa(int(bonusHistory.Index))
		}

	case "PendingGoodSale":
		buffer.WriteString("📣📣📣[HH bán hàng giỏi]📣📣📣\n")
		sRank = ""

	case "SaleRetail":
		buffer.WriteString("📣📣📣[HH bán lẻ]📣📣📣\n")
		sRank = ""

	case "Diamond":
		buffer.WriteString("📣📣📣[HH diamond]📣📣📣\n")
		sRank = ""

	case "CrownDiamond":
		buffer.WriteString("📣📣📣[HH crown diamond]📣📣📣\n")
		sRank = ""
	}

	buffer.WriteString("📌 ")
	buffer.WriteString(fmt.Sprintf("%s - ", bonusHistory.Address))
	if sRank != "" {
		buffer.WriteString(fmt.Sprintf("%s - ", sRank))
	}

	if sF != "F" {
		buffer.WriteString(fmt.Sprintf("%s - ", sF))
	}

	if bonusHistory.Rate > 0 {
		sRate := strconv.Itoa(int(bonusHistory.Rate / 10))
		buffer.WriteString(fmt.Sprintf("%s%% - ", sRate))
	}

	buffer.WriteString(fmt.Sprintf("%s USDT", utils.FloatToString(float64(bonusHistory.Amount)/1_000_000, 4)))
	return s.SendNoti(buffer.Bytes())
}

func (s *TeleService) SendBuyProductNoti(data *models.EBuyProductData, app string) error {
	var buffer bytes.Buffer
	buffer.WriteString(fmt.Sprintf("📣📣📣[Buy Product - %s]📣📣📣\n", app))
	buffer.WriteString(fmt.Sprintf("📌 MTN address: %s\n", data.Add))
	for i, v := range data.Quantities {
		buffer.WriteString(fmt.Sprintf("📌 Quantity: %s\n", strconv.Itoa(v)))
		buffer.WriteString(fmt.Sprintf("📌 Pack: %s\n", utils.FloatToString(float64(data.Prices[i])/1_000_000, 4)))
	}
	buffer.WriteString(fmt.Sprintf("📌 Total amount: %s\n", utils.FloatToString(float64(data.TotalPrice)/1_000_000, 4)))
	return s.SendNoti(buffer.Bytes())
}
