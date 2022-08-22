require('dotenv').config()

import socket from 'socket.io'
import express from 'express'
import mongoose from 'mongoose'
import consola from 'consola'
import bodyParser from 'body-parser'

import NodeCache from 'node-cache'
export const cache = new NodeCache()

import axios from 'axios'
import axiosRetry from 'axios-retry'

axiosRetry(axios, { retries: 3 })
import { Nuxt, Builder } from 'nuxt'

import config from '../nuxt.config.js'
//import sign from './sign'
import upload from './upload/ipfs'
import { startUpdaters } from './updaters'

import { serverInit } from './utils'
import { subscribe, unsubscribe } from './markets/sockets'

import { markets } from './markets'
import { pools } from './pools'
import { account } from './account'
import { cs } from './coinswitch'

const app = express()

// Import and Set Nuxt.js options
config.dev = process.env.NODE_ENV !== 'production'

async function start () {
  //db sync
  if (!process.env.DISABLE_DB) {
    try {
      const uri = process.env.DB_STRING_CONNECTION || 'mongodb://localhost:27017/alcor_dev'
      await mongoose.connect(uri, { useUnifiedTopology: true, useNewUrlParser: true })
      console.log('MongoDB connected!')
    } catch (e) {
      console.log(e)
      throw new Error('MongoDB connect err')
    }
  }

  app.use(serverInit)

  // Before bodyParser coz use formidable
  app.use('/api/upload', upload)

  // Parsers
  app.use(bodyParser.urlencoded({ extended: true }))
  app.use(bodyParser.json())

  // Server routes
  app.use('/api/markets', markets)
  app.use('/api/account', account)
  app.use('/api/pools', pools)
  app.use('/api/coinswitch', cs)

  // Init Nuxt.js
  const nuxt = new Nuxt(config)

  const { host, port } = nuxt.options.server

  console.log('DOCKER_TAG', process.env.DOCKER_TAG)

  // NuxtJS
  if (!process.env.DISABLE_UI) {
    await nuxt.ready()
    if (config.dev) {
      const builder = new Builder(nuxt)
      await builder.build()
    }
    app.use(nuxt.render)
  }

  // Listen the server
  const server = app.listen(port, host)
  consola.ready({
    message: `Server listening on http://${host}:${port}`,
    badge: true
  })

  if (process.env.DISABLE_DB) return

  const io = socket(server)

  io.on('connection', socket => {
    subscribe(io, socket)
    unsubscribe(io, socket)
  })

  app.set('io', io)

  startUpdaters(app)
}

start()
