from fastapi import FastAPI, Request
from fastapi.openapi.docs import get_swagger_ui_html
from fastapi.openapi.utils import get_openapi
from fastapi.responses import HTMLResponse, JSONResponse

from .routers import (
    auth,
    food_logs,
    foods,
    health_profiles,
    meal_items,
    meal_logs,
    nutrition_targets,
    saved_meals,
    user_goals,
    users,
    weight_entries,
)

DOCS_THEME_TOGGLE_CSS = """
<style>
  .swagger-theme-toggle {
    position: fixed;
    top: 1rem;
    right: 1rem;
    z-index: 10000;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.45rem 0.55rem;
    border-radius: 999px;
    font-family: sans-serif;
    background: rgba(15, 23, 42, 0.78);
    border: 1px solid rgba(148, 163, 184, 0.28);
    box-shadow: 0 10px 30px rgba(2, 6, 23, 0.28);
    backdrop-filter: blur(14px);
  }

  .swagger-theme-toggle__label {
    font-size: 0.875rem;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.85);
  }

  .swagger-theme-toggle__buttons {
    display: inline-flex;
    border-radius: 999px;
    padding: 0.2rem;
    background: rgba(255, 255, 255, 0.08);
    border: 1px solid rgba(255, 255, 255, 0.12);
  }

  .swagger-theme-toggle__button {
    border: 0;
    border-radius: 999px;
    padding: 0.4rem 0.9rem;
    background: transparent;
    color: rgba(255, 255, 255, 0.88);
    font-size: 0.85rem;
    font-weight: 700;
    cursor: pointer;
    transition: background 0.18s ease, color 0.18s ease, transform 0.18s ease;
  }

  .swagger-theme-toggle__button:hover {
    transform: translateY(-1px);
  }

  html[data-swagger-theme="light"] .swagger-theme-toggle__button[data-theme="light"],
  html[data-swagger-theme="dark"] .swagger-theme-toggle__button[data-theme="dark"] {
    background: rgba(255, 255, 255, 0.95);
    color: #0f172a;
  }

  html[data-swagger-theme="light"] .swagger-theme-toggle__buttons {
    background: rgba(15, 23, 42, 0.08);
    border-color: rgba(15, 23, 42, 0.12);
  }

  html[data-swagger-theme="light"] .swagger-theme-toggle {
    background: rgba(255, 255, 255, 0.92);
    border-color: rgba(15, 23, 42, 0.12);
    box-shadow: 0 10px 30px rgba(15, 23, 42, 0.12);
  }

  html[data-swagger-theme="light"] .swagger-theme-toggle__label {
    color: #0f172a;
  }

  @media (max-width: 720px) {
    .swagger-theme-toggle {
      top: 0.75rem;
      right: 0.75rem;
      transform: scale(0.94);
      transform-origin: top right;
    }
  }
</style>
"""

DARK_SWAGGER_CSS = """
<style id="swagger-dark-theme" media="not all">
  :root {
    --bg: #0b1220;
    --bg-soft: #111827;
    --bg-elevated: #172033;
    --bg-parameters: #1a2336;
    --border: #334155;
    --text: #e5eefb;
    --text-soft: #94a3b8;
    --accent: #38bdf8;
    --accent-soft: #0f172a;
    --green: #34d399;
    --red: #f87171;
    --yellow: #fbbf24;
  }

  body,
  .swagger-ui {
    background: var(--bg);
    color: var(--text);
  }

  body {
    margin: 0;
  }

  .swagger-ui .topbar {
    background: linear-gradient(90deg, #0f172a, #111827);
    border-bottom: 1px solid var(--border);
  }

  .swagger-ui .topbar .download-url-wrapper {
    display: none;
  }

  .swagger-ui .wrapper,
  .swagger-ui .info,
  .swagger-ui .opblock-body,
  .swagger-ui .opblock-section,
  .swagger-ui .responses-wrapper,
  .swagger-ui .parameters-container,
  .swagger-ui .execute-wrapper,
  .swagger-ui .body-param,
  .swagger-ui .body-param__text,
  .swagger-ui .response-wrapper,
  .swagger-ui .models,
  .swagger-ui section.models,
  .swagger-ui .model-container,
  .swagger-ui .auth-wrapper {
    background: transparent !important;
  }

  .swagger-ui .info .title,
  .swagger-ui .info p,
  .swagger-ui .info li,
  .swagger-ui .info a,
  .swagger-ui .scheme-container,
  .swagger-ui .opblock-tag,
  .swagger-ui .parameter__name,
  .swagger-ui .parameter__type,
  .swagger-ui .response-col_status,
  .swagger-ui .response-col_description,
  .swagger-ui .tab li,
  .swagger-ui label,
  .swagger-ui .opblock-description-wrapper p,
  .swagger-ui .opblock-external-docs-wrapper p,
  .swagger-ui .opblock-title_normal p,
  .swagger-ui section.models h4,
  .swagger-ui section.models h5,
  .swagger-ui .model-title,
  .swagger-ui .model,
  .swagger-ui .prop,
  .swagger-ui .prop-type,
  .swagger-ui .markdown p,
  .swagger-ui .markdown code,
  .swagger-ui .btn,
  .swagger-ui select,
  .swagger-ui input,
  .swagger-ui textarea,
  .swagger-ui h1,
  .swagger-ui h2,
  .swagger-ui h3,
  .swagger-ui h4,
  .swagger-ui h5,
  .swagger-ui h6,
  .swagger-ui td,
  .swagger-ui th,
  .swagger-ui .parameter__in,
  .swagger-ui .table-container,
  .swagger-ui .renderedMarkdown p,
  .swagger-ui .renderedMarkdown code,
  .swagger-ui .response-control-media-type__title,
  .swagger-ui .opblock-summary-description {
    color: var(--text);
  }

  .swagger-ui .scheme-container,
  .swagger-ui .information-container.wrapper,
  .swagger-ui .opblock,
  .swagger-ui .responses-inner,
  .swagger-ui .model-box,
  .swagger-ui .dialog-ux .modal-ux,
  .swagger-ui .dialog-ux .modal-ux-content,
  .swagger-ui .opblock-section-header,
  .swagger-ui .response-col_links,
  .swagger-ui .responses-table,
  .swagger-ui .tab,
  .swagger-ui .auth-container,
  .swagger-ui .auth-btn-wrapper,
  .swagger-ui .auth-container .scope-def,
  .swagger-ui .auth-container .scopes,
  .swagger-ui .response-control-media-type--accept-controller select,
  .swagger-ui .parameters-col_description,
  .swagger-ui .parameter__extension,
  .swagger-ui table tbody tr td,
  .swagger-ui table thead tr th {
    background: var(--bg-soft) !important;
    border-color: var(--border) !important;
  }

  .swagger-ui .opblock-tag {
    border-bottom: 1px solid var(--border);
  }

  .swagger-ui .opblock .opblock-summary,
  .swagger-ui .opblock .opblock-section-header,
  .swagger-ui .responses-table td,
  .swagger-ui .responses-table th,
  .swagger-ui .parameter__name,
  .swagger-ui .parameters-col_description,
  .swagger-ui .parameter__type,
  .swagger-ui .response-control-media-type {
    border-color: var(--border) !important;
  }

  .swagger-ui .opblock.opblock-get {
    background: rgba(56, 189, 248, 0.08);
    border-color: rgba(56, 189, 248, 0.35);
  }

  .swagger-ui .opblock.opblock-post {
    background: rgba(52, 211, 153, 0.08);
    border-color: rgba(52, 211, 153, 0.35);
  }

  .swagger-ui .opblock.opblock-put {
    background: rgba(251, 191, 36, 0.08);
    border-color: rgba(251, 191, 36, 0.35);
  }

  .swagger-ui .opblock.opblock-delete {
    background: rgba(248, 113, 113, 0.08);
    border-color: rgba(248, 113, 113, 0.35);
  }

  .swagger-ui .opblock.opblock-get .opblock-summary-method {
    background: #0ea5e9;
  }

  .swagger-ui .opblock.opblock-post .opblock-summary-method {
    background: #34d399;
  }

  .swagger-ui .opblock.opblock-put .opblock-summary-method {
    background: #fbbf24;
    color: #1f2937;
  }

  .swagger-ui .opblock.opblock-delete .opblock-summary-method {
    background: #f87171;
  }

  .swagger-ui .btn.execute {
    background: var(--accent);
    border-color: var(--accent);
    color: #082f49;
  }

  .swagger-ui .btn.authorize {
    background: var(--bg-elevated);
    border-color: var(--accent);
    color: var(--text);
  }

  .swagger-ui .btn,
  .swagger-ui .btn.try-out__btn,
  .swagger-ui .btn.cancel,
  .swagger-ui .btn.clear,
  .swagger-ui .btn.authorize,
  .swagger-ui .authorization__btn,
  .swagger-ui .opblock-control-arrow {
    background: var(--bg-elevated) !important;
    border-color: var(--border) !important;
    color: var(--text) !important;
    box-shadow: none !important;
  }

  .swagger-ui .btn:hover,
  .swagger-ui .btn.try-out__btn:hover,
  .swagger-ui .btn.cancel:hover,
  .swagger-ui .btn.clear:hover,
  .swagger-ui .btn.authorize:hover {
    border-color: var(--accent) !important;
    color: var(--accent) !important;
  }

  .swagger-ui select,
  .swagger-ui input,
  .swagger-ui textarea {
    background: var(--bg-elevated) !important;
    border: 1px solid var(--border) !important;
  }

  .swagger-ui .responses-table .response td,
  .swagger-ui .responses-table .response th {
    background: transparent;
  }

  .swagger-ui .opblock-description-wrapper,
  .swagger-ui .opblock-external-docs-wrapper,
  .swagger-ui .opblock-title_normal,
  .swagger-ui .response-col_description__inner,
  .swagger-ui .parameter__name.required span,
  .swagger-ui .prop-format,
  .swagger-ui .scheme-container .schemes > label,
  .swagger-ui .auth-container h4,
  .swagger-ui .auth-container p,
  .swagger-ui .scope-def {
    color: var(--text-soft) !important;
  }

  .swagger-ui .parameters-container,
  .swagger-ui .opblock-section-header {
    background: var(--bg-parameters) !important;
  }

  .swagger-ui .parameters-container {
    border-top: 1px solid var(--border) !important;
    border-bottom: 1px solid var(--border) !important;
  }

  .swagger-ui .highlight-code,
  .swagger-ui pre,
  .swagger-ui .microlight {
    background: #020617 !important;
    color: #dbeafe !important;
  }

  .swagger-ui .microlight,
  .swagger-ui .highlight-code .microlight,
  .swagger-ui .example,
  .swagger-ui .example * {
    color: #dbeafe !important;
  }

  .swagger-ui .model-toggle:after,
  .swagger-ui .expand-methods,
  .swagger-ui .expand-operation {
    filter: invert(1) brightness(1.2);
  }
</style>
"""

SWAGGER_THEME_BOOTSTRAP_SCRIPT = """
<script>
  (function () {
    var storageKey = "swagger-ui-theme";
    var defaultTheme = "dark";

    function getStoredTheme() {
      try {
        return localStorage.getItem(storageKey) || defaultTheme;
      } catch (error) {
        return defaultTheme;
      }
    }

    function setStoredTheme(theme) {
      try {
        localStorage.setItem(storageKey, theme);
      } catch (error) {
      }
    }

    function applyTheme(theme) {
      var darkTheme = document.getElementById("swagger-dark-theme");
      var root = document.documentElement;
      var resolvedTheme = theme === "light" ? "light" : "dark";

      if (darkTheme) {
        darkTheme.media = resolvedTheme === "dark" ? "all" : "not all";
      }

      root.setAttribute("data-swagger-theme", resolvedTheme);
      window.__swaggerTheme = resolvedTheme;
      setStoredTheme(resolvedTheme);

      var lightButton = document.getElementById("swagger-theme-light");
      var darkButton = document.getElementById("swagger-theme-dark");
      if (lightButton) {
        lightButton.setAttribute("aria-pressed", String(resolvedTheme === "light"));
      }
      if (darkButton) {
        darkButton.setAttribute("aria-pressed", String(resolvedTheme === "dark"));
      }
    }

    window.__applySwaggerTheme = applyTheme;
    applyTheme(getStoredTheme());
  })();
</script>
"""

SWAGGER_THEME_TOGGLE_HTML = """
<div id="swagger-theme-toggle" class="swagger-theme-toggle" aria-label="Swagger theme toggle">
  <span class="swagger-theme-toggle__label">Theme</span>
  <div class="swagger-theme-toggle__buttons">
    <button
      type="button"
      id="swagger-theme-light"
      class="swagger-theme-toggle__button"
      data-theme="light"
      aria-pressed="false"
    >
      Light
    </button>
    <button
      type="button"
      id="swagger-theme-dark"
      class="swagger-theme-toggle__button"
      data-theme="dark"
      aria-pressed="true"
    >
      Dark
    </button>
  </div>
</div>
"""

SWAGGER_THEME_TOGGLE_SCRIPT = """
<script>
  (function () {
    function bindThemeToggle() {
      var lightButton = document.getElementById("swagger-theme-light");
      var darkButton = document.getElementById("swagger-theme-dark");
      if (!lightButton || !darkButton) {
        return;
      }

      lightButton.addEventListener("click", function () {
        window.__applySwaggerTheme("light");
      });

      darkButton.addEventListener("click", function () {
        window.__applySwaggerTheme("dark");
      });

      if (window.__applySwaggerTheme) {
        window.__applySwaggerTheme(window.__swaggerTheme || "dark");
      }
    }

    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bindThemeToggle);
    } else {
      bindThemeToggle();
    }
  })();
</script>
"""

OPENAPI_PATH = "/openapi.json"

app = FastAPI(title="MyHealthTrackr API", docs_url=None, openapi_url=None)


@app.middleware("http")
async def disable_docs_caching(request: Request, call_next):
    response = await call_next(request)

    if request.url.path in {"/docs", "/openapi.json"}:
        response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "0"

    return response


@app.get("/openapi.json", include_in_schema=False)
def custom_openapi_schema() -> JSONResponse:
    schema = get_openapi(
        title=app.title,
        version="0.1.0",
        routes=app.routes,
    )
    return JSONResponse(
        schema,
        headers={
            "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
            "Pragma": "no-cache",
            "Expires": "0",
        },
    )


@app.get("/docs", include_in_schema=False)
def custom_swagger_ui() -> HTMLResponse:
    swagger_ui = get_swagger_ui_html(
        openapi_url=OPENAPI_PATH,
        title=f"{app.title} Docs",
    )
    html = swagger_ui.body.decode("utf-8")
    html = html.replace(
        "</head>",
        f"{DOCS_THEME_TOGGLE_CSS}{DARK_SWAGGER_CSS}{SWAGGER_THEME_BOOTSTRAP_SCRIPT}</head>",
    )
    html = html.replace(
        "</body>",
        f"{SWAGGER_THEME_TOGGLE_HTML}{SWAGGER_THEME_TOGGLE_SCRIPT}</body>",
    )
    return HTMLResponse(html)


@app.get("/", tags=["System"])
def root():
    return {"message": "MyHealthTrackr API is running!"}


@app.get("/health", tags=["System"])
def health_check():
    return {"status": "ok"}


app.include_router(auth.router)
app.include_router(foods.router)
app.include_router(health_profiles.router)
app.include_router(users.router)
app.include_router(user_goals.router)
app.include_router(nutrition_targets.router)
app.include_router(food_logs.router)
app.include_router(meal_logs.router)
app.include_router(meal_items.router)
app.include_router(saved_meals.router)
app.include_router(weight_entries.router)
