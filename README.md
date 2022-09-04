# aws-etc

# 월 비용 보기
aws ce get-cost-and-usage --time-period Start=2022-08-01,End=2022-08-30 --granularity MONTHLY --metrics  BlendedCost | jq '.ResultsByTime[].Total.BlendedCost'
