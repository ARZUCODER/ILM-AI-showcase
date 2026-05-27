package api

import (
	_ "embed"
	"net/http"

	"github.com/gin-gonic/gin"
)

//go:embed panel.html
var panelHTML string

// servePanel returns the embedded admin panel single-page app.
func servePanel(c *gin.Context) {
	c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(panelHTML))
}
