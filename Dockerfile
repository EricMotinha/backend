# ---- runtime ----
FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=8080

# Dependência de runtime para libs nativas (ex.: argon2)
RUN apk add --no-cache libstdc++

COPY --from=build /app/package*.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist

EXPOSE 8080
CMD ["node", "dist/main.js"]
