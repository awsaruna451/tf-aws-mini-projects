// src/lambda.ts
// Entry point used when running inside AWS Lambda.
// Your existing src/main.ts (used for local dev with `start:dev`) is untouched.
import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { ExpressAdapter } from '@nestjs/platform-express';
import serverlessExpress from '@codegenie/serverless-express';
import express from 'express';
import { Callback, Context, Handler } from 'aws-lambda';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

let server: Handler;

async function bootstrap(): Promise<Handler> {
  const expressApp = express();
  const app = await NestFactory.create(
    AppModule,
    new ExpressAdapter(expressApp),
  );

  app.useGlobalPipes(new ValidationPipe());
  app.enableCors();

  await app.init();

  return serverlessExpress({ app: expressApp });
}

export const handler: Handler = async (
  event: any,
  context: Context,
  callback: Callback,
) => {
  // Reuse the bootstrapped app across warm invocations
  server = server ?? (await bootstrap());

  // API Gateway HTTP API (v2) includes the stage name in the incoming path
  // (e.g. /dev/cats) unless the stage is $default. NestJS's router only
  // knows about /cats, so strip the stage prefix before passing it on.
  const stage = event.requestContext?.stage;
  if (stage && stage !== '$default') {
    if (event.rawPath?.startsWith(`/${stage}`)) {
      event.rawPath = event.rawPath.slice(`/${stage}`.length) || '/';
    }
    if (event.path?.startsWith(`/${stage}`)) {
      event.path = event.path.slice(`/${stage}`.length) || '/';
    }
  }

  return server(event, context, callback);
};