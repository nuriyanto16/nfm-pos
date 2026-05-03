package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// visitor stores request count and reset time per IP
type visitor struct {
	count    int
	lastSeen time.Time
}

var (
	rateMu   sync.Mutex
	visitors = make(map[string]*visitor)
)

// cleanup old entries every 10 minutes
func init() {
	go func() {
		for {
			time.Sleep(10 * time.Minute)
			rateMu.Lock()
			for ip, v := range visitors {
				if time.Since(v.lastSeen) > 15*time.Minute {
					delete(visitors, ip)
				}
			}
			rateMu.Unlock()
		}
	}()
}

// RateLimiter limits to maxRequests per window duration per IP
func RateLimiter(maxRequests int, window time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()

		rateMu.Lock()
		v, exists := visitors[ip]
		if !exists || time.Since(v.lastSeen) > window {
			visitors[ip] = &visitor{count: 1, lastSeen: time.Now()}
			rateMu.Unlock()
			c.Next()
			return
		}

		v.count++
		v.lastSeen = time.Now()
		if v.count > maxRequests {
			rateMu.Unlock()
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error": "Terlalu banyak permintaan. Silakan coba lagi dalam beberapa menit.",
			})
			return
		}
		rateMu.Unlock()
		c.Next()
	}
}
