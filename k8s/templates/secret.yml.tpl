
apiVersion: v1
kind: Secret
metadata:
  name: bulletin-board-secret
  namespace: bulletin-board
type: Opaque
stringData:
  SPRING_DATASOURCE_USERNAME: "${DB_USERNAME}"
  SPRING_DATASOURCE_PASSWORD: "${DB_PASSWORD}"
  STORAGE_S3_ACCESSKEY: "${S3_ACCESS_KEY}"
  STORAGE_S3_SECRETKEY: "${S3_SECRET_KEY}"