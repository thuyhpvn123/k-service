package handlers

import (
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/repositories"
)

type Handlers struct {
	BonusHistory           *BonusHistoryHandler
	DiscountHistory        *DiscountHistoryHandler
	EBuyProductDataHistory *EBuyProductDataHistoryHandler
	SubInfoHistory         *SubInfoHistoryHandler
	LogHistory             *LogHistoryHandler
}

func NewHandlers(repos *repositories.Repositories, kvenABI *abi.ABI) *Handlers {
	return &Handlers{
		BonusHistory:           NewBonusHistoryHandler(repos.BonusHistory, kvenABI),
		DiscountHistory:        NewDiscountHistoryHandler(repos.DiscountHistory),
		EBuyProductDataHistory: NewEBuyProductDataHistoryHandler(repos.EBuyProductDataHistory, repos.LogHistory, repos.SubInfoHistory),
		SubInfoHistory:         NewSubInfoHistoryHandler(repos.SubInfoHistory, repos.EBuyProductDataHistory),
		LogHistory:             NewLogHistoryHandler(repos.LogHistory, repos.LogStatusHistory),
	}
}
