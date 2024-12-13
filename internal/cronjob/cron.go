package cronjob

import (
	"github.com/meta-node-blockchain/meta-node/pkg/logger"
	"github.com/robfig/cron/v3"

	// "github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/repositories"
	// "time"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/api/handlers"
)

var cronjob *cron.Cron

func Start(
	handlers *handlers.Handlers,
) {
	logger.Info("Cronjob Started")
	cronjob = cron.New()
	cronjob.AddFunc("* * * * *", func() { CheckLogoutEveryMinute(handlers) })
	logger.Warn("Start Cron Job CheckLogoutEveryMinute", "* * * * *")

	cronjob.Start()
}

func Stop() {
	cronjob.Stop()
}

func CheckLogoutEveryMinute(h *handlers.Handlers) {
	err := h.LogHistory.CheckLogoutEveryMinute()
	if err != nil {
		logger.Error("Err when CheckLogout")
	}
}
