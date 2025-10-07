# =================================================================
# OJAYEK MESSARI SDK BOT v6.2 - ENHANCED INSTALLATION SCRIPT
# Using Official @messari/sdk-ts Package
# =================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Configuration
$rootDir = "C:\Projects"
$projectName = "ojayek-messari-sdk-bot"
$projectPath = Join-Path $rootDir $projectName
$logFile = Join-Path $env:TEMP "ojayek-install.log"

# Logging function
function Write-Log {
    param([string]$Message, [string]$Color = "White", [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Type] $Message"
    Write-Host $logMessage -ForegroundColor $Color
    Add-Content -Path $logFile -Value $logMessage
}

# Check prerequisites
function Test-Prerequisites {
    Write-Log "Checking system prerequisites..." "Cyan"
    
    # Check Node.js
    $nodeVersion = node --version 2>$null
    if (-not $nodeVersion) {
        Write-Log "Node.js is not installed. Please install Node.js 18+ from https://nodejs.org" "Red" "ERROR"
        return $false
    }
    
    $nodeMajor = [int]($nodeVersion -replace 'v' -split '\.' | Select-Object -First 1)
    if ($nodeMajor -lt 18) {
        Write-Log "Node.js version $nodeVersion is too old. Please upgrade to Node.js 18+" "Red" "ERROR"
        return $false
    }
    
    Write-Log "Node.js $nodeVersion detected" "Green"
    
    # Check npm
    $npmVersion = npm --version 2>$null
    if (-not $npmVersion) {
        Write-Log "npm is not available" "Red" "ERROR"
        return $false
    }
    
    Write-Log "npm $npmVersion detected" "Green"
    
    # Check disk space
    $drive = Get-PSDrive -Name C
    $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
    if ($freeSpaceGB -lt 2) {
        Write-Log "Low disk space: $freeSpaceGB GB free. Minimum 2 GB required." "Yellow" "WARNING"
    } else {
        Write-Log "Disk space: $freeSpaceGB GB free" "Green"
    }
    
    return $true
}

# Main installation
try {
    Write-Log "Starting Ojayek Messari SDK Bot v6.2 Installation" "Cyan"
    
    # Display banner
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "  OJAYEK MESSARI SDK BOT v6.2 - ENHANCED INSTALLATION" -ForegroundColor Cyan
    Write-Host "  Using Official @messari/sdk-ts" -ForegroundColor Cyan
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Prerequisites)) {
        throw "System prerequisites not met. Please review the errors above."
    }

    # Create root directory
    if (-not (Test-Path $rootDir)) {
        New-Item -ItemType Directory -Path $rootDir -Force | Out-Null
        Write-Log "[✓] Root directory created: $rootDir" "Green"
    }

    # Clean and create project directory
    if (Test-Path $projectPath) {
        Write-Log "[!] Removing existing project..." "Yellow" "WARN"
        Remove-Item -Path $projectPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
    Write-Log "[✓] Project directory created: $projectPath" "Green"

    # =================================================================
    # BACKEND SETUP
    # =================================================================
    Write-Log "`n[1/4] Setting up Backend structure..." "Cyan"

    $backendPath = Join-Path $projectPath "backend"
    $dirs = @(
        "$backendPath\src\services",
        "$backendPath\src\strategies",
        "$backendPath\src\utils",
        "$backendPath\data",
        "$backendPath\logs"
    )

    foreach ($dir in $dirs) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Write-Log "[✓] Backend directories created" "Green"

    # Backend package.json
    $backendPackageJson = @'
{
  "name": "ojayek-messari-sdk-backend",
  "version": "6.2.0",
  "description": "Crypto Trading Bot Backend using Official Messari SDK TypeScript",
  "type": "module",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "node --watch src/index.js",
    "test": "node --test"
  },
  "keywords": [ "crypto", "trading", "messari", "sdk", "bot" ],
  "author": "Ojayek Development Team",
  "license": "MIT",
  "dependencies": {
    "@messari/sdk": "^0.0.9",
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "node-cron": "^3.0.3",
    "winston": "^3.11.0",
    "sqlite3": "^5.1.6",
    "axios": "^1.6.2"
  },
  "devDependencies": { "@types/node": "^20.10.0" },
  "engines": { "node": ">=18.0.0" }
}
'@
    Set-Content -Path "$backendPath\package.json" -Value $backendPackageJson -Encoding UTF8

    # Backend .env
    $backendEnv = @'
# Messari SDK Configuration
MESSARI_SDK_API_KEY=your_messari_api_key_here

# Server Configuration
PORT=3000
NODE_ENV=production

# Scheduling (Cron format for Tehran timezone)
SCHEDULE_MORNING=0 8 * * *
SCHEDULE_EVENING=0 19 * * *
TIMEZONE=Asia/Tehran

# Trading Strategy Parameters
TOP_ASSETS_COUNT=10
MIN_MARKET_CAP=100000000
CONFIDENCE_THRESHOLD=60

# Analysis Weights (must sum to 100)
WEIGHT_TECHNICAL=35
WEIGHT_FUNDAMENTAL=30
WEIGHT_SENTIMENT=20
WEIGHT_VOLUME=15

# Database
DB_PATH=./data/trading.db

# Logging
LOG_LEVEL=info
LOG_FILE=./logs/app.log
'@
    Set-Content -Path "$backendPath\.env" -Value $backendEnv -Encoding UTF8

    # Backend Files (messariService.js, tradingStrategy.js, etc.)
    # Note: These files are sourced from the user's provided script.
    $messariService = @'
import MessariSDK from '@messari/sdk-ts';
import logger from '../utils/logger.js';

class MessariService {
    constructor() {
        this.client = new MessariSDK({
            apiKey: process.env.MESSARI_SDK_API_KEY
        });
        this.isInitialized = false;
    }

    async initialize() {
        try {
            logger.info('Initializing Messari SDK...');
            await this.checkHealth();
            this.isInitialized = true;
            logger.info('✓ Messari SDK initialized successfully');
            return true;
        } catch (error) {
            logger.error('Failed to initialize Messari SDK:', error);
            throw error;
        }
    }

    async checkHealth() {
        try {
            const response = await this.client.assets.v2.assets.retrieveList({ limit: 1 });
            return { status: 'healthy', sdk: 'connected', timestamp: new Date().toISOString() };
        } catch (error) {
            logger.error('Health check failed:', error);
            throw new Error('Messari SDK connection failed');
        }
    }

    async getTopAssets(limit = 10) {
        try {
            logger.info(`Fetching top ${limit} assets...`);
            const response = await this.client.assets.v2.assets.retrieveList({ limit: limit, sort: 'market_cap', order: 'desc' });
            const assets = [];
            for await (const asset of response) {
                if (!asset || !asset.symbol) continue;
                assets.push({
                    symbol: asset.symbol,
                    name: asset.name || asset.symbol,
                    slug: asset.slug,
                    marketCap: asset.metrics?.marketcap?.current_marketcap_usd || 0,
                    price: asset.metrics?.market_data?.price_usd || 0,
                    volume24h: asset.metrics?.market_data?.volume_last_24_hours || 0,
                    percentChange24h: asset.metrics?.market_data?.percent_change_usd_last_24_hours || 0,
                    percentChange7d: asset.metrics?.market_data?.percent_change_usd_last_7_days || 0,
                    circulatingSupply: asset.metrics?.supply?.circulating || 0,
                    maxSupply: asset.metrics?.supply?.max || null
                });
            }
            logger.info(`✓ Fetched ${assets.length} assets`);
            return assets;
        } catch (error) {
            logger.error('Error fetching top assets:', error);
            throw error;
        }
    }

    async getAssetDetails(symbol) {
        try {
            logger.info(`Fetching details for ${symbol}...`);
            const response = await this.client.assets.v2.assets.retrieve(symbol, { fields: 'id,symbol,name,slug,metrics' });
            if (!response || !response.data) throw new Error(`No data found for ${symbol}`);
            const asset = response.data;
            const metrics = asset.metrics || {};
            const marketData = metrics.market_data || {};
            const supply = metrics.supply || {};
            return {
                symbol: asset.symbol, name: asset.name, slug: asset.slug,
                marketCap: metrics.marketcap?.current_marketcap_usd || 0, price: marketData.price_usd || 0,
                volume24h: marketData.volume_last_24_hours || 0, percentChange24h: marketData.percent_change_usd_last_24_hours || 0,
                percentChange7d: marketData.percent_change_usd_last_7_days || 0, percentChange30d: marketData.percent_change_usd_last_30_days || 0,
                volatility: marketData.volatility || 0, circulatingSupply: supply.circulating || 0, maxSupply: supply.max || null,
                allTimeHigh: marketData.ohlcv_last_24_hour?.high || 0, allTimeLow: marketData.ohlcv_last_24_hour?.low || 0
            };
        } catch (error) {
            logger.error(`Error fetching details for ${symbol}:`, error);
            throw error;
        }
    }

    async getAIInsights(query = "What are the top performing crypto sectors today?") {
        try {
            logger.info('Fetching AI market insights...');
            const response = await this.client.ai.openai.chat.generateCompletion({ messages: [{ role: 'user', content: query }] });
            if (!response || !response.choices || response.choices.length === 0) {
                logger.warn('No AI insights received');
                return null;
            }
            const content = response.choices[0].message?.content || '';
            logger.info('✓ AI insights received');
            return { query: query, response: content, timestamp: new Date().toISOString() };
        } catch (error) {
            logger.warn('AI insights not available:', error.message);
            return null;
        }
    }

    async getNewsFeed(assetIds = [], limit = 20) {
        try {
            logger.info('Fetching news feed...');
            const params = { limit: limit, page: 1 };
            if (assetIds && assetIds.length > 0) params.assetIds = assetIds;
            const response = await this.client.news.v1.news.retrieveFeed(params);
            const news = [];
            for await (const article of response) {
                if (!article) continue;
                news.push({
                    title: article.title, url: article.url, publishedAt: article.published_at,
                    source: article.source?.name || 'Unknown', assets: article.references?.assets || []
                });
            }
            logger.info(`✓ Fetched ${news.length} news articles`);
            return news;
        } catch (error) {
            logger.error('Error fetching news:', error);
            return [];
        }
    }

    calculateVolumeRatio(volume24h, marketCap) {
        if (!marketCap || marketCap === 0) return 0;
        return (volume24h / marketCap) * 100;
    }

    async getMarketOverview() {
        try {
            logger.info('Fetching market overview...');
            const [topAssets, aiInsights, news] = await Promise.allSettled([
                this.getTopAssets(10),
                this.getAIInsights("Summarize current crypto market conditions and sentiment"),
                this.getNewsFeed([], 5)
            ]);
            return {
                topAssets: topAssets.status === 'fulfilled' ? topAssets.value : [],
                aiInsights: aiInsights.status === 'fulfilled' ? aiInsights.value : null,
                recentNews: news.status === 'fulfilled' ? news.value : [],
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            logger.error('Error fetching market overview:', error);
            throw error;
        }
    }
}
export default new MessariService();
'@
    Set-Content -Path "$backendPath\src\services\messariService.js" -Value $messariService -Encoding UTF8

    $tradingStrategy = @'
import messariService from '../services/messariService.js';
import logger from '../utils/logger.js';

class TradingStrategy {
    constructor() {
        this.weights = {
            technical: parseFloat(process.env.WEIGHT_TECHNICAL) || 35,
            fundamental: parseFloat(process.env.WEIGHT_FUNDAMENTAL) || 30,
            sentiment: parseFloat(process.env.WEIGHT_SENTIMENT) || 20,
            volume: parseFloat(process.env.WEIGHT_VOLUME) || 15
        };
        this.minMarketCap = parseFloat(process.env.MIN_MARKET_CAP) || 100000000;
        this.confidenceThreshold = parseFloat(process.env.CONFIDENCE_THRESHOLD) || 60;
    }

    analyzeTechnical(asset) {
        let score = 0; const reasons = [];
        if (asset.percentChange24h > 5) { score += 30; reasons.push('Strong 24h momentum (+5%)'); }
        else if (asset.percentChange24h > 2) { score += 15; reasons.push('Positive 24h momentum'); }
        else if (asset.percentChange24h < -5) { score -= 30; reasons.push('Weak 24h performance (-5%)'); }
        if (asset.percentChange7d > 10) { score += 25; reasons.push('Strong weekly trend (+10%)'); }
        if (asset.volatility && asset.volatility < 0.02) { score += 10; reasons.push('Low volatility (stable)'); }
        return { score: Math.max(-100, Math.min(100, score)), reasons };
    }

    analyzeFundamental(asset) {
        let score = 0; const reasons = [];
        if (asset.marketCap > 10000000000) { score += 30; reasons.push('Large cap (>$10B)'); }
        else if (asset.marketCap > 1000000000) { score += 20; reasons.push('Mid cap ($1B-$10B)'); }
        if (asset.maxSupply && asset.circulatingSupply) {
            const supplyRatio = asset.circulatingSupply / asset.maxSupply;
            if (supplyRatio > 0.9) { score += 15; reasons.push('High supply circulation (>90%)'); }
        }
        if (asset.allTimeHigh && asset.price) {
            const percentFromATH = ((asset.price - asset.allTimeHigh) / asset.allTimeHigh) * 100;
            if (percentFromATH > -20) { score += 20; reasons.push('Near ATH (within 20%)'); }
        }
        return { score: Math.max(-100, Math.min(100, score)), reasons };
    }

    async analyzeSentiment(asset, marketContext) {
        let score = 0; const reasons = [];
        if (marketContext && marketContext.aiInsights) {
            const insights = marketContext.aiInsights.response || ''; const symbol = asset.symbol.toLowerCase();
            if (insights.toLowerCase().includes(symbol)) {
                if (insights.includes('bullish') || insights.includes('positive')) { score += 30; reasons.push('Positive AI sentiment'); }
            }
        }
        if (marketContext && marketContext.recentNews) {
            const relevantNews = marketContext.recentNews.filter(article => article.assets.some(a => a.symbol === asset.symbol));
            if (relevantNews.length > 0) { score += 15; reasons.push(`${relevantNews.length} recent news mentions`); }
        }
        return { score: Math.max(-100, Math.min(100, score)), reasons };
    }

    analyzeVolume(asset) {
        let score = 0; const reasons = [];
        const volumeRatio = messariService.calculateVolumeRatio(asset.volume24h, asset.marketCap);
        if (volumeRatio > 50) { score += 40; reasons.push('Very high volume ratio (>50%)'); }
        else if (volumeRatio > 20) { score += 25; reasons.push('High volume ratio (>20%)'); }
        if (asset.volume24h > 1000000000) { score += 15; reasons.push('High absolute volume (>$1B)'); }
        return { score: Math.max(-100, Math.min(100, score)), reasons };
    }

    async calculateSignal(asset, marketContext) {
        try {
            const technical = this.analyzeTechnical(asset); const fundamental = this.analyzeFundamental(asset);
            const sentiment = await this.analyzeSentiment(asset, marketContext); const volume = this.analyzeVolume(asset);
            const totalScore = ((technical.score * this.weights.technical / 100) + (fundamental.score * this.weights.fundamental / 100) + (sentiment.score * this.weights.sentiment / 100) + (volume.score * this.weights.volume / 100));
            let signalType;
            if (totalScore >= 45) { signalType = 'BUY'; } else if (totalScore <= -45) { signalType = 'SELL'; } else { signalType = 'HOLD'; }
            const confidence = Math.min(100, Math.abs(totalScore) * 1.2);
            return {
                symbol: asset.symbol, name: asset.name, signal: signalType,
                score: Math.round(totalScore * 10) / 10, confidence: Math.round(confidence), price: asset.price,
                marketCap: asset.marketCap, volume24h: asset.volume24h, percentChange24h: asset.percentChange24h,
                breakdown: { technical: Math.round(technical.score), fundamental: Math.round(fundamental.score), sentiment: Math.round(sentiment.score), volume: Math.round(volume.score) },
                reasons: [...technical.reasons, ...fundamental.reasons, ...sentiment.reasons, ...volume.reasons],
                timestamp: new Date().toISOString()
            };
        } catch (error) { logger.error(`Error calculating signal for ${asset.symbol}:`, error); throw error; }
    }

    async analyzeMarket(limit = 10) {
        try {
            logger.info(`Starting market analysis for top ${limit} assets...`);
            const [topAssets, marketContext] = await Promise.all([ messariService.getTopAssets(limit), messariService.getMarketOverview() ]);
            if (!topAssets || topAssets.length === 0) throw new Error('No assets data received');
            const signals = [];
            for (const asset of topAssets) {
                try {
                    const detailedAsset = await messariService.getAssetDetails(asset.symbol);
                    const signal = await this.calculateSignal(detailedAsset, marketContext);
                    signals.push(signal);
                    logger.info(`${asset.symbol}: ${signal.signal} (Score: ${signal.score}, Confidence: ${signal.confidence}%)`);
                    await new Promise(resolve => setTimeout(resolve, 500));
                } catch (error) { logger.warn(`Failed to analyze ${asset.symbol}:`, error.message); continue; }
            }
            logger.info(`✓ Analysis complete. Generated ${signals.length} signals`);
            return {
                signals,
                summary: { totalAnalyzed: topAssets.length, signalsGenerated: signals.length, buySignals: signals.filter(s => s.signal === 'BUY').length, sellSignals: signals.filter(s => s.signal === 'SELL').length, holdSignals: signals.filter(s => s.signal === 'HOLD').length, highConfidence: signals.filter(s => s.confidence >= this.confidenceThreshold).length },
                marketContext, timestamp: new Date().toISOString()
            };
        } catch (error) { logger.error('Market analysis failed:', error); throw error; }
    }
}
export default new TradingStrategy();
'@
    Set-Content -Path "$backendPath\src\strategies\tradingStrategy.js" -Value $tradingStrategy -Encoding UTF8
    
    $database = @'
import sqlite3 from 'sqlite3';
import { promisify } from 'util';
import logger from './logger.js';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';
const __filename = fileURLToPath(import.meta.url); const __dirname = path.dirname(__filename);
class Database {
    constructor() { this.db = null; this.dbPath = process.env.DB_PATH || path.join(__dirname, '../../data/trading.db'); }
    async initialize() {
        try {
            const dataDir = path.dirname(this.dbPath); if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });
            this.db = new sqlite3.Database(this.dbPath, (err) => { if (err) { logger.error('Database connection error:', err); throw err; } });
            this.db.run = promisify(this.db.run.bind(this.db)); this.db.get = promisify(this.db.get.bind(this.db)); this.db.all = promisify(this.db.all.bind(this.db));
            await this.createTables(); logger.info('✓ Database initialized successfully');
        } catch (error) { logger.error('Failed to initialize database:', error); throw error; }
    }
    async createTables() {
        await this.db.run(`CREATE TABLE IF NOT EXISTS signals (id INTEGER PRIMARY KEY, symbol TEXT NOT NULL, name TEXT, signal TEXT NOT NULL, score REAL, confidence INTEGER, price REAL, market_cap REAL, volume_24h REAL, percent_change_24h REAL, technical_score REAL, fundamental_score REAL, sentiment_score REAL, volume_score REAL, reasons TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)`);
        await this.db.run(`CREATE TABLE IF NOT EXISTS analysis_runs (id INTEGER PRIMARY KEY, total_analyzed INTEGER, signals_generated INTEGER, buy_signals INTEGER, sell_signals INTEGER, hold_signals INTEGER, high_confidence INTEGER, status TEXT, error_message TEXT, started_at DATETIME, completed_at DATETIME DEFAULT CURRENT_TIMESTAMP)`);
        await this.db.run(`CREATE TABLE IF NOT EXISTS portfolio (id INTEGER PRIMARY KEY, symbol TEXT UNIQUE NOT NULL, name TEXT, entry_price REAL, current_price REAL, quantity REAL DEFAULT 1, signal TEXT, confidence INTEGER, entry_date DATETIME, last_updated DATETIME DEFAULT CURRENT_TIMESTAMP, status TEXT DEFAULT 'active')`);
        logger.info('✓ Database tables ready');
    }
    async saveSignal(signal) {
        const result = await this.db.run(`INSERT INTO signals (symbol, name, signal, score, confidence, price, market_cap, volume_24h, percent_change_24h, technical_score, fundamental_score, sentiment_score, volume_score, reasons) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [signal.symbol, signal.name, signal.signal, signal.score, signal.confidence, signal.price, signal.marketCap, signal.volume24h, signal.percentChange24h, signal.breakdown.technical, signal.breakdown.fundamental, signal.breakdown.sentiment, signal.breakdown.volume, JSON.stringify(signal.reasons)]);
        return result.lastID;
    }
    async saveAnalysisRun(analysis) { const result = await this.db.run(`INSERT INTO analysis_runs (total_analyzed, signals_generated, buy_signals, sell_signals, hold_signals, high_confidence, status, started_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`, [analysis.totalAnalyzed, analysis.signalsGenerated, analysis.buySignals, analysis.sellSignals, analysis.holdSignals, analysis.highConfidence, 'completed', new Date().toISOString()]); return result.lastID; }
    async updatePortfolio(signal) { if (signal.signal === 'BUY' && signal.confidence >= parseInt(process.env.CONFIDENCE_THRESHOLD || 60)) { await this.db.run(`INSERT OR REPLACE INTO portfolio (symbol, name, entry_price, current_price, signal, confidence, entry_date, last_updated) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`, [signal.symbol, signal.name, signal.price, signal.price, signal.signal, signal.confidence, new Date().toISOString(), new Date().toISOString()]); logger.info(`Portfolio updated: Added ${signal.symbol}`); } }
    async getSignals(limit = 50, symbol = null) { let query = 'SELECT * FROM signals'; const params = []; if (symbol) { query += ' WHERE symbol = ?'; params.push(symbol); } query += ' ORDER BY created_at DESC LIMIT ?'; params.push(limit); const signals = await this.db.all(query, params); return signals.map(s => ({ ...s, reasons: JSON.parse(s.reasons || '[]') })); }
    async getPortfolio() { return await this.db.all(`SELECT * FROM portfolio WHERE status = 'active' ORDER BY last_updated DESC`); }
    async getAnalyticsData() { const [signalStats, recentRuns, portfolioStats] = await Promise.all([this.db.get(`SELECT COUNT(*) as total_signals, SUM(CASE WHEN signal = 'BUY' THEN 1 ELSE 0 END) as buy_count, SUM(CASE WHEN signal = 'SELL' THEN 1 ELSE 0 END) as sell_count, AVG(confidence) as avg_confidence FROM signals WHERE created_at >= datetime('now', '-7 days')`), this.db.all(`SELECT * FROM analysis_runs ORDER BY completed_at DESC LIMIT 10`), this.db.get(`SELECT COUNT(*) as active_positions, AVG(confidence) as avg_confidence FROM portfolio WHERE status = 'active'`)]); return { signalStats, recentRuns, portfolioStats }; }
    async checkHealth() { try { await this.db.get('SELECT 1'); return { status: 'healthy', database: 'connected' }; } catch (error) { return { status: 'unhealthy', database: 'disconnected', error: error.message }; } }
    async close() { if (this.db) { this.db.close(); logger.info('Database connection closed'); } }
}
export default new Database();
'@
    Set-Content -Path "$backendPath\src\utils\database.js" -Value $database -Encoding UTF8

    $logger = @'
import winston from 'winston';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';
const __filename = fileURLToPath(import.meta.url); const __dirname = path.dirname(__filename);
const logsDir = path.join(__dirname, '../../logs');
if (!fs.existsSync(logsDir)) fs.mkdirSync(logsDir, { recursive: true });
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }), winston.format.errors({ stack: true }), winston.format.splat(), winston.format.json()),
    defaultMeta: { service: 'ojayek-bot' },
    transports: [
        new winston.transports.File({ filename: path.join(logsDir, 'error.log'), level: 'error' }),
        new winston.transports.File({ filename: path.join(logsDir, 'app.log') })
    ]
});
if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: winston.format.combine(winston.format.colorize(), winston.format.simple())
    }));
}
export default logger;
'@
    Set-Content -Path "$backendPath\src\utils\logger.js" -Value $logger -Encoding UTF8

    $indexJs = @'
import express from 'express'; import cors from 'cors'; import cron from 'node-cron'; import dotenv from 'dotenv';
import messariService from './services/messariService.js'; import tradingStrategy from './strategies/tradingStrategy.js';
import database from './utils/database.js'; import logger from './utils/logger.js';
dotenv.config(); const app = express(); const PORT = process.env.PORT || 3000;
app.use(cors()); app.use(express.json()); let isAnalyzing = false;
async function initializeServices() { logger.info('🚀 OJAYEK MESSARI SDK BOT v6.2 - Starting...'); await database.initialize(); await messariService.initialize(); logger.info('✓ All services initialized successfully'); }
async function runAnalysis() {
    if (isAnalyzing) { logger.warn('Analysis already in progress, skipping...'); return null; }
    isAnalyzing = true; logger.info(`📊 Starting scheduled analysis...`);
    try {
        const analysis = await tradingStrategy.analyzeMarket(parseInt(process.env.TOP_ASSETS_COUNT) || 10);
        for (const signal of analysis.signals) { await database.saveSignal(signal); await database.updatePortfolio(signal); }
        await database.saveAnalysisRun(analysis.summary);
        logger.info(`✓ Analysis completed successfully: Buy: ${analysis.summary.buySignals} | Sell: ${analysis.summary.sellSignals} | Hold: ${analysis.summary.holdSignals}`);
        return analysis;
    } catch (error) { logger.error('Analysis failed:', error); throw error; } finally { isAnalyzing = false; }
}
app.get('/api/health', async (req, res) => { const [messariHealth, dbHealth] = await Promise.all([messariService.checkHealth(), database.checkHealth()]); res.json({ status: 'healthy', services: { messari: messariHealth, database: dbHealth } }); });
app.get('/api/status', (req, res) => res.json({ version: '6.2.0', sdk: '@messari/sdk-ts', isAnalyzing, uptime: process.uptime() }));
app.get('/api/signals', async (req, res) => { const { limit = 50, symbol } = req.query; res.json(await database.getSignals(parseInt(limit), symbol)); });
app.get('/api/signals/:symbol', async (req, res) => res.json(await database.getSignals(50, req.params.symbol.toUpperCase())));
app.get('/api/portfolio', async (req, res) => res.json(await database.getPortfolio()));
app.get('/api/analytics', async (req, res) => res.json(await database.getAnalyticsData()));
app.post('/api/analyze', async (req, res) => { if (isAnalyzing) return res.status(409).json({ error: 'Analysis already in progress' }); const analysis = await runAnalysis(); res.json({ message: 'Analysis completed', data: analysis }); });
function setupScheduledJobs() {
    const morning = process.env.SCHEDULE_MORNING || '0 8 * * *'; const evening = process.env.SCHEDULE_EVENING || '0 19 * * *'; const timezone = process.env.TIMEZONE || 'Asia/Tehran';
    cron.schedule(morning, () => runAnalysis(), { timezone }); cron.schedule(evening, () => runAnalysis(), { timezone });
    logger.info(`✓ Scheduled jobs configured: Morning: ${morning}, Evening: ${evening} (${timezone})`);
}
async function startServer() { await initializeServices(); setupScheduledJobs(); app.listen(PORT, () => logger.info(`✓ Server running on port ${PORT}`)); }
process.on('SIGINT', async () => { logger.info('Shutting down gracefully...'); await database.close(); process.exit(0); });
startServer().catch(error => { logger.error('Failed to start server:', error); process.exit(1); });
'@
    Set-Content -Path "$backendPath\src\index.js" -Value $indexJs -Encoding UTF8
    Write-Log "[✓] Backend files created" "Green"

    # =================================================================
    # FRONTEND SETUP
    # =================================================================
    Write-Log "`n[2/4] Setting up Frontend structure..." "Cyan"

    $frontendPath = Join-Path $projectPath "frontend"
    New-Item -ItemType Directory -Path "$frontendPath\assets\js" -Force | Out-Null
    New-Item -ItemType Directory -Path "$frontendPath\assets\css" -Force | Out-Null
    
    # Frontend package.json
    $frontendPackageJson = @'
{
  "name": "ojayek-messari-sdk-frontend",
  "version": "6.2.0",
  "description": "Frontend UI for Ojayek Messari Bot",
  "main": "main.js",
  "scripts": {
    "start": "electron ."
  },
  "dependencies": {
    "electron": "^28.0.0"
  },
  "author": "Ojayek Development Team",
  "license": "MIT"
}
'@
    Set-Content -Path "$frontendPath\package.json" -Value $frontendPackageJson -Encoding UTF8

    # Frontend main.js (Electron)
    $mainJs = @'
const { app, BrowserWindow } = require('electron');
const path = require('path');

function createWindow () {
  const win = new BrowserWindow({
    width: 1400,
    height: 900,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  win.loadFile('index.html');
  win.webContents.openDevTools(); // Open DevTools by default
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
'@
    Set-Content -Path "$frontendPath\main.js" -Value $mainJs -Encoding UTF8
    
    # Frontend preload.js (Electron)
    $preloadJs = @'
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
    // We can define secure API bridges here if needed in the future
    // Example: send: (channel, data) => ipcRenderer.send(channel, data)
});
'@
    Set-Content -Path "$frontendPath\preload.js" -Value $preloadJs -Encoding UTF8

    # Frontend index.html
    $indexHtml = @'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Ojayek Messari SDK Bot v6.2</title>
    <meta http-equiv="Content-Security-Policy" content="script-src 'self' 'unsafe-inline';">
    <link rel="stylesheet" href="./assets/css/styles.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>Ojayek Messari SDK Bot v6.2</h1>
            <div id="status-bar">Status: <span id="status-light" class="orange"></span> <span id="status-text">Connecting...</span></div>
        </header>
        <main>
            <div id="dashboard">
                <!-- Dashboard content will be loaded here by JS -->
            </div>
            <div id="signals-log">
                <h2>Recent Signals</h2>
                <div id="signals-container"></div>
            </div>
        </main>
    </div>
    <script src="./assets/js/renderer.js"></script>
</body>
</html>
'@
    Set-Content -Path "$frontendPath\index.html" -Value $indexHtml -Encoding UTF8
    
    # Frontend styles.css
    $stylesCss = @'
body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background-color: #1a1a1a; color: #e0e0e0; margin: 0; padding: 20px; }
.container { max-width: 1600px; margin: auto; }
header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #444; padding-bottom: 10px; margin-bottom: 20px; }
h1, h2 { color: #4dd0e1; }
#status-bar { font-size: 0.9em; }
#status-light { display: inline-block; width: 10px; height: 10px; border-radius: 50%; margin-right: 5px; }
.green { background-color: #4caf50; } .red { background-color: #f44336; } .orange { background-color: #ff9800; }
#dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 20px; margin-bottom: 30px; }
.card { background-color: #2c2c2c; padding: 20px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.3); }
.card h3 { margin-top: 0; border-bottom: 1px solid #444; padding-bottom: 10px; }
#signals-log h2 { margin-bottom: 15px; }
#signals-container { max-height: 500px; overflow-y: auto; }
.signal { background: #2c2c2c; border-left: 5px solid; padding: 15px; margin-bottom: 10px; border-radius: 5px; display: grid; grid-template-columns: 1fr 1fr 1fr 1fr 2fr; gap: 10px; align-items: center; }
.signal.BUY { border-color: #4caf50; } .signal.SELL { border-color: #f44336; } .signal.HOLD { border-color: #ffc107; }
.signal-symbol { font-weight: bold; font-size: 1.2em; }
.signal-price, .signal-score, .signal-confidence { font-size: 0.9em; }
'@
    Set-Content -Path "$frontendPath\assets\css\styles.css" -Value $stylesCss -Encoding UTF8

    # Frontend renderer.js
    $rendererJs = @'
const API_BASE_URL = 'http://localhost:3000/api';

const statusLight = document.getElementById('status-light');
const statusText = document.getElementById('status-text');
const dashboardEl = document.getElementById('dashboard');
const signalsContainer = document.getElementById('signals-container');

function formatNumber(num) {
    if (num >= 1e12) return `$${(num / 1e12).toFixed(2)}T`;
    if (num >= 1e9) return `$${(num / 1e9).toFixed(2)}B`;
    if (num >= 1e6) return `$${(num / 1e6).toFixed(2)}M`;
    if (num >= 1e3) return `$${(num / 1e3).toFixed(2)}K`;
    return `$${num.toFixed(2)}`;
}

async function fetchData(endpoint) {
    try {
        const response = await fetch(`${API_BASE_URL}${endpoint}`);
        if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        return await response.json();
    } catch (error) {
        console.error(`Error fetching ${endpoint}:`, error);
        statusLight.className = 'red';
        statusText.textContent = `Error: ${error.message}`;
        return null;
    }
}

function createSignalElement(signal) {
    const el = document.createElement('div');
    el.className = `signal ${signal.signal}`;
    el.innerHTML = `
        <div class="signal-symbol">${signal.symbol}</div>
        <div class="signal-price">Price: ${formatNumber(signal.price)}</div>
        <div class="signal-score">Score: ${signal.score}</div>
        <div class="signal-confidence">Confidence: ${signal.confidence}%</div>
        <div class="signal-reasons">Reasons: ${JSON.parse(signal.reasons || '[]').join(', ')}</div>
    `;
    return el;
}

async function updateDashboard() {
    const analytics = await fetchData('/analytics');
    if (!analytics) return;
    
    dashboardEl.innerHTML = `
        <div class="card"><h3>Signals (Last 7d)</h3><p>Total: ${analytics.signalStats.total_signals || 0}</p><p>Buy: ${analytics.signalStats.buy_count || 0}</p><p>Sell: ${analytics.signalStats.sell_count || 0}</p></div>
        <div class="card"><h3>Portfolio</h3><p>Active Positions: ${analytics.portfolioStats.active_positions || 0}</p><p>Avg. Confidence: ${Math.round(analytics.portfolioStats.avg_confidence || 0)}%</p></div>
        <div class="card"><h3>Last Run</h3><p>Signals: ${analytics.recentRuns[0]?.signals_generated || 'N/A'}</p><p>Completed: ${new Date(analytics.recentRuns[0]?.completed_at).toLocaleString() || 'N/A'}</p></div>
    `;
}

async function updateSignals() {
    const signalsData = await fetchData('/signals?limit=50');
    if (!signalsData) return;
    
    signalsContainer.innerHTML = '';
    signalsData.forEach(signal => {
        signalsContainer.appendChild(createSignalElement(signal));
    });
}

async function checkHealth() {
    const health = await fetchData('/health');
    if (health && health.status === 'healthy') {
        statusLight.className = 'green';
        statusText.textContent = 'Backend Connected';
    } else {
        statusLight.className = 'red';
        statusText.textContent = 'Backend Disconnected';
    }
}

function init() {
    checkHealth();
    updateDashboard();
    updateSignals();
    setInterval(checkHealth, 30000); // Check health every 30s
    setInterval(updateDashboard, 60000); // Refresh dashboard every 60s
    setInterval(updateSignals, 60000); // Refresh signals every 60s
}

document.addEventListener('DOMContentLoaded', init);
'@
    Set-Content -Path "$frontendPath\assets\js\renderer.js" -Value $rendererJs -Encoding UTF8
    Write-Log "[✓] Frontend files created" "Green"

    # =================================================================
    # Final Steps: Scripts, README, and Dependency Installation
    # =================================================================
    Write-Log "`n[3/4] Creating startup scripts and documentation..." "Cyan"

    # start-backend.bat
    $startBackend = '@echo off & echo Starting Ojayek Backend... & cd backend & npm start & pause'
    Set-Content -Path "$projectPath\start-backend.bat" -Value $startBackend -Encoding UTF8

    # start-frontend.bat
    $startFrontend = '@echo off & echo Starting Ojayek Frontend... & cd frontend & npm start & pause'
    Set-Content -Path "$projectPath\start-frontend.bat" -Value $startFrontend -Encoding UTF8
    
    # README.md
    $readme = @"
# Ojayek Messari SDK Bot v6.2

Welcome to the Ojayek Messari SDK Bot! This application uses the official Messari TypeScript SDK to analyze cryptocurrency markets and generate trading signals.

## Quick Start

1.  **Configure API Key**: Open `backend/.env` and enter your Messari API key in `MESSARI_SDK_API_KEY`.
2.  **Install Dependencies**: Open a terminal in the `$projectPath` directory and run:
    - `cd backend && npm install`
    - `cd frontend && npm install`
3.  **Run the Application**:
    - **Backend**: Open a terminal and run `cd backend && npm start`.
    - **Frontend**: Open another terminal and run `cd frontend && npm start`.

Alternatively, on Windows, you can use the provided `.bat` files after installing dependencies.
"@
    Set-Content -Path "$projectPath\README.md" -Value $readme -Encoding UTF8
    Write-Log "[✓] Startup scripts and README created" "Green"

    # Install dependencies
    Write-Log "`n[4/4] Installing dependencies (this may take a few minutes)..." "Cyan"
    
    Write-Log "Installing Backend dependencies..." "Yellow"
    Set-Location -Path $backendPath
    npm install
    
    Write-Log "Installing Frontend dependencies..." "Yellow"
    Set-Location -Path $frontendPath
    npm install
    
    Set-Location -Path $projectPath
    
    # Final summary
    Write-Host "`n" -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "  ✓ INSTALLATION COMPLETE!" -ForegroundColor Green
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📁 Project location: $projectPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📋 Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Open the file '$backendPath\.env' in a text editor." -ForegroundColor White
    Write-Host "  2. Add your Messari API key to the 'MESSARI_SDK_API_KEY' variable." -ForegroundColor White
    Write-Host ""
    Write-Host "🚀 To run the bot:" -ForegroundColor Cyan
    Write-Host "   - Double-click 'start-backend.bat' in the project folder." -ForegroundColor Gray
    Write-Host "   - In a separate window, double-click 'start-frontend.bat'." -ForegroundColor Gray
    Write-Host ""
    Write-Host "For detailed instructions, see the README.md file in the project directory."
    Write-Host "==================================================================" -ForegroundColor Cyan

} catch {
    Write-Log "An error occurred during installation: $($_.Exception.Message)" "Red" "FATAL"
    Write-Host "`nInstallation failed. Please check the log file at $logFile for details." -ForegroundColor Red
}
# OJAYEK MESSARI SDK BOT INSTALLATION SCRIPT - END      
