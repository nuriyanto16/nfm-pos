package handlers

import (
	"fmt"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type Pagination struct {
	Page       int         `json:"page"`
	Limit      int         `json:"limit"`
	TotalRows  int64       `json:"total_rows"`
	TotalPages int         `json:"total_pages"`
	Rows       interface{} `json:"rows"`
}

func Paginate(c *gin.Context, db *gorm.DB, rows interface{}) (*Pagination, error) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}

	var totalRows int64
	if err := db.Session(&gorm.Session{}).Model(rows).Count(&totalRows).Error; err != nil {
		fmt.Printf("Pagination Count Error: %v\n", err)
		return nil, err
	}

	totalPages := int((totalRows + int64(limit) - 1) / int64(limit))
	offset := (page - 1) * limit

	if err := db.Session(&gorm.Session{}).Offset(offset).Limit(limit).Find(rows).Error; err != nil {
		fmt.Printf("Pagination Find Error: %v\n", err)
		return nil, err
	}

	return &Pagination{
		Page:       page,
		Limit:      limit,
		TotalRows:  totalRows,
		TotalPages: totalPages,
		Rows:       rows,
	}, nil
}
