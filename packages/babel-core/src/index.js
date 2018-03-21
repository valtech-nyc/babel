// @flow

export { default as File } from "./transformation/file/file";
export {
  default as buildExternalHelpers,
} from "./tools/build-external-helpers";
export { resolvePlugin, resolvePreset } from "./config/files";

export { version } from "../package.json";
export { getEnv } from "./config/helpers/environment";

export * as types from "@babel/types";
export { default as traverse } from "@babel/traverse";
export { default as template } from "@babel/template";

export { loadPartialConfig, loadOptions, OptionManager } from "./config";

export { createConfigItem } from "./config/item";

export function Plugin(alias: string) {
  throw new Error(
    `The (${alias}) Babel 5 plugin is being run with an unsupported Babel version.`,
  );
}

export { default as transform } from "./transform";
export { default as transformSync } from "./transform-sync";

export { default as transformFile } from "./transform-file";
export { default as transformFileSync } from "./transform-file-sync";

export { default as transformFromAst } from "./transform-ast";
export { default as transformFromAstSync } from "./transform-ast-sync";

export { default as parse } from "./parse";

/**
 * Recommended set of compilable extensions. Not used in @babel/core directly, but meant as
 * as an easy source for tooling making use of @babel/core.
 */
export const DEFAULT_EXTENSIONS = Object.freeze([
  ".js",
  ".jsx",
  ".es6",
  ".es",
  ".mjs",
]);
