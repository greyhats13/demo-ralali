package main

import (
	"encoding/json"
	"net/http"
)

func main() {
	http.HandleFunc("/", demoHandler)
	if err := http.ListenAndServe(":8080", nil); err != nil {
		panic(err)
	}
}

func demoHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Add("Content-Type", "application/json")
	resp, _ := json.Marshal(map[string]string{
		"IP Sumber": getSourceIp(r),
		"IP Tujuan": getDestinationIp(r),
	})
	w.Write(resp)
}

func getSourceIp(r *http.Request) string {
	forwarded := r.Header.Get("X-Forwarded-For")
	if forwarded != "" {
		return forwarded
	}
	return r.RemoteAddr
}

func getDestinationIp(r *http.Request) string {
	realip := r.Header.Get("X-Real-Ip")
	if realip != "" {
		return realip
	}
	return r.RemoteAddr
}
