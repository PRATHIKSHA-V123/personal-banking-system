# =============================================================
#  PERSONAL BANKING SYSTEM
#  A single-file Shiny (R) web application
#  Author: <your name here>
# =============================================================

library(shiny)
library(shinyjs)

# ---------------------------------------------------------------
# 1. DATA LAYER  (simple file-based "database" using RDS files)
# ---------------------------------------------------------------
ACCOUNTS_FILE     <- "accounts.rds"
TRANSACTIONS_FILE <- "transactions.rds"

init_data <- function() {
  if (!file.exists(ACCOUNTS_FILE)) {
    accounts <- data.frame(
      acc_no    = c("PB10001"),
      username  = c("demo"),
      password  = c("demo123"),
      pin       = c("1234"),
      full_name = c("Demo User"),
      balance   = c(5000),
      created   = as.character(Sys.Date()),
      stringsAsFactors = FALSE
    )
    saveRDS(accounts, ACCOUNTS_FILE)
  }
  if (!file.exists(TRANSACTIONS_FILE)) {
    transactions <- data.frame(
      acc_no  = character(),
      type    = character(),
      amount  = numeric(),
      balance = numeric(),
      note    = character(),
      time    = character(),
      stringsAsFactors = FALSE
    )
    saveRDS(transactions, TRANSACTIONS_FILE)
  }
}
init_data()

read_accounts     <- function() readRDS(ACCOUNTS_FILE)
write_accounts    <- function(df) saveRDS(df, ACCOUNTS_FILE)
read_transactions <- function() readRDS(TRANSACTIONS_FILE)
write_transactions<- function(df) saveRDS(df, TRANSACTIONS_FILE)

next_acc_no <- function(df) {
  if (nrow(df) == 0) return("PB10001")
  nums <- as.numeric(gsub("PB", "", df$acc_no))
  sprintf("PB%05d", max(nums) + 1)
}

log_transaction <- function(acc_no, type, amount, balance, note = "") {
  tx <- read_transactions()
  tx <- rbind(tx, data.frame(
    acc_no = acc_no, type = type, amount = amount,
    balance = balance, note = note,
    time = as.character(Sys.time()), stringsAsFactors = FALSE
  ))
  write_transactions(tx)
}

# ---------------------------------------------------------------
# 2. UI
# ---------------------------------------------------------------
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
    tags$link(rel = "stylesheet",
              href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css"),
    tags$title("Personal Banking System")
  ),

  # ---------- NAVBAR ----------
  div(class = "navbar",
      div(class = "navbar-brand", icon("piggy-bank"), "PB Bank"),
      div(id = "nav_user_area", class = "navbar-right", uiOutput("nav_right"))
  ),

  # ---------- LANDING / AUTH SCREEN ----------
  div(id = "landing_page",
      div(class = "hero",
          div(class = "hero-text",
              h1("Banking made simple, secure & personal."),
              p("Manage your money with a clean dashboard: deposit, withdraw, transfer and track every transaction in real time."),
              div(class = "hero-badges",
                  span(icon("shield-halved"), " Secure"),
                  span(icon("bolt"), " Instant"),
                  span(icon("chart-line"), " Transparent")
              )
          ),
          div(class = "auth-card",
              tabsetPanel(id = "auth_tabs", type = "pills",
                tabPanel("Login",
                  br(),
                  textInput("login_username", "Username", placeholder = "e.g. demo"),
                  passwordInput("login_password", "Password", placeholder = "e.g. demo123"),
                  actionButton("btn_login", "Login", class = "btn-primary btn-block"),
                  div(class = "hint", "Try the demo account -> username: demo / password: demo123"),
                  textOutput("login_msg")
                ),
                tabPanel("Register",
                  br(),
                  textInput("reg_name", "Full Name"),
                  textInput("reg_username", "Choose a Username"),
                  passwordInput("reg_password", "Choose a Password"),
                  passwordInput("reg_pin", "Set a 4-digit Transfer PIN", placeholder = "e.g. 4321"),
                  numericInput("reg_deposit", "Opening Deposit (₹)", value = 500, min = 0),
                  actionButton("btn_register", "Create Account", class = "btn-primary btn-block"),
                  textOutput("register_msg")
                )
              )
          )
      ),
      div(class = "feature-strip",
          div(class = "feature", icon("wallet"), h4("Track Balance"), p("Real-time balance updates after every action.")),
          div(class = "feature", icon("right-left"), h4("Transfer Funds"), p("Send money instantly to any account number.")),
          div(class = "feature", icon("clock-rotate-left"), h4("Full History"), p("Every deposit, withdrawal & transfer logged.")),
          div(class = "feature", icon("lock"), h4("Private"), p("Your data stays local to this app instance."))
      ),
      tags$footer("© 2026 Personal Banking System — Built with R Shiny")
  ),

  # ---------- DASHBOARD (shown after login) ----------
  hidden(
    div(id = "dashboard_page",
        div(class = "dash-wrap",
            # sidebar
            div(class = "sidebar",
                actionLink("side_overview", tagList(icon("gauge-high"), "Overview"), class = "sidebar-item active"),
                actionLink("side_deposit", tagList(icon("money-bill-wave"), "Deposit"), class = "sidebar-item"),
                actionLink("side_withdraw", tagList(icon("money-bill-transfer"), "Withdraw"), class = "sidebar-item"),
                actionLink("side_transfer", tagList(icon("right-left"), "Transfer"), class = "sidebar-item"),
                actionLink("side_history", tagList(icon("clock-rotate-left"), "Transaction History"), class = "sidebar-item"),
                actionLink("side_logout", tagList(icon("right-from-bracket"), "Logout"), class = "sidebar-item logout")
            ),
            # main content
            div(class = "dash-main",
                uiOutput("balance_cards"),

                div(id = "panel_overview", class = "panel-block",
                    h3("Recent Activity"),
                    tableOutput("overview_table")
                ),

                hidden(div(id = "panel_deposit", class = "panel-block",
                    h3("Deposit Money"),
                    numericInput("deposit_amount", "Amount (₹)", value = 100, min = 1),
                    actionButton("btn_deposit", "Deposit", class = "btn-primary"),
                    textOutput("deposit_msg")
                )),

                hidden(div(id = "panel_withdraw", class = "panel-block",
                    h3("Withdraw Money"),
                    numericInput("withdraw_amount", "Amount (₹)", value = 100, min = 1),
                    actionButton("btn_withdraw", "Withdraw", class = "btn-primary"),
                    textOutput("withdraw_msg")
                )),

                hidden(div(id = "panel_transfer", class = "panel-block",
                    h3("Transfer Money"),
                    textInput("transfer_to", "Recipient Account Number", placeholder = "e.g. PB10002"),
                    uiOutput("recipient_preview"),
                    numericInput("transfer_amount", "Amount (₹)", value = 100, min = 1),
                    actionButton("btn_transfer", "Send Money", class = "btn-primary"),
                    textOutput("transfer_msg")
                )),

                hidden(div(id = "panel_history", class = "panel-block",
                    h3("All Transactions"),
                    tableOutput("history_table")
                ))
            )
        )
    )
  )
)

# ---------------------------------------------------------------
# 3. SERVER
# ---------------------------------------------------------------
server <- function(input, output, session) {

  current_user <- reactiveVal(NULL)   # holds acc_no of logged-in user
  refresh_flag <- reactiveVal(0)

  bump <- function() refresh_flag(refresh_flag() + 1)

  # ---------- SHARED PIN VERIFICATION MODAL ----------
  # Any sensitive action (view balance, deposit, withdraw, transfer) routes
  # through here: it stashes the action name, prompts for the PIN, and only
  # runs the actual do_* function once the PIN matches.
  pending_action <- reactiveVal(NULL)
  pin_error      <- reactiveVal("")
  output$pin_modal_error <- renderText(pin_error())

  request_pin <- function(action, label) {
    pending_action(action)
    pin_error("")
    updateTextInput(session, "pin_confirm_input", value = "")
    showModal(modalDialog(
      title = tagList(icon("lock"), paste0(" Enter PIN to ", label)),
      div(style = "text-align:center;",
          passwordInput("pin_confirm_input", NULL, placeholder = "••••"),
          div(style = "color:#e5484d; font-size:13px; font-weight:600;",
              textOutput("pin_modal_error"))
      ),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("pin_confirm_btn", "Confirm", class = "btn-primary")
      ),
      easyClose = TRUE
    ))
  }

  observeEvent(input$pin_confirm_btn, {
    req(current_user(), pending_action())
    accounts <- read_accounts()
    idx <- which(accounts$acc_no == current_user())
    entered <- input$pin_confirm_input
    if (is.null(entered) || nchar(entered) == 0 || entered != accounts$pin[idx]) {
      pin_error("Incorrect PIN. Please try again.")
      updateTextInput(session, "pin_confirm_input", value = "")
      return()
    }
    removeModal()
    action <- pending_action()
    pending_action(NULL)
    switch(action,
      balance  = show_balance(TRUE),
      deposit  = do_deposit(),
      withdraw = do_withdraw(),
      transfer = do_transfer()
    )
  })

  # ---------- LOGIN ----------
  observeEvent(input$btn_login, {
    accounts <- read_accounts()
    row <- accounts[accounts$username == input$login_username &
                     accounts$password == input$login_password, ]
    if (nrow(row) == 1) {
      current_user(row$acc_no[1])
      hide("landing_page"); show("dashboard_page")
      bump()
    } else {
      output$login_msg <- renderText("Invalid username or password.")
    }
  })

  # ---------- REGISTER ----------
  observeEvent(input$btn_register, {
    req(input$reg_username, input$reg_password, input$reg_name)
    accounts <- read_accounts()
    if (input$reg_username %in% accounts$username) {
      output$register_msg <- renderText("Username already taken.")
      return()
    }
    if (!grepl("^[0-9]{4}$", input$reg_pin)) {
      output$register_msg <- renderText("PIN must be exactly 4 digits.")
      return()
    }
    new_acc <- next_acc_no(accounts)
    accounts <- rbind(accounts, data.frame(
      acc_no = new_acc, username = input$reg_username,
      password = input$reg_password, pin = input$reg_pin,
      full_name = input$reg_name,
      balance = input$reg_deposit, created = as.character(Sys.Date()),
      stringsAsFactors = FALSE
    ))
    write_accounts(accounts)
    log_transaction(new_acc, "Opening Deposit", input$reg_deposit, input$reg_deposit)
    output$register_msg <- renderText(
      paste("Account created! Your account number is", new_acc, "- please login.")
    )
    updateTabsetPanel(session, "auth_tabs", selected = "Login")
  })

  # ---------- LOGOUT ----------
  observeEvent(input$side_logout, {
    current_user(NULL)
    show_balance(FALSE)
    show("landing_page"); hide("dashboard_page")
  })

  # ---------- SIDEBAR NAVIGATION ----------
  nav_ids <- c("overview", "deposit", "withdraw", "transfer", "history")
  lapply(nav_ids, function(id) {
    observeEvent(input[[paste0("side_", id)]], {
      lapply(nav_ids, function(other) {
        toggle(paste0("panel_", other), condition = (other == id))
        shinyjs::removeClass(selector = ".sidebar-item", class = "active")
      })
      shinyjs::addClass(id = paste0("side_", id), class = "active")
    })
  })

  # ---------- TOP-RIGHT NAV / BALANCE CARDS ----------
  my_account <- reactive({
    refresh_flag()
    req(current_user())
    accounts <- read_accounts()
    accounts[accounts$acc_no == current_user(), ]
  })

  output$nav_right <- renderUI({
    if (is.null(current_user())) return(NULL)
    acc <- my_account()
    span(icon("user-circle"), paste0(" ", acc$full_name, " (", acc$acc_no, ")"))
  })

  show_balance <- reactiveVal(FALSE)
  observeEvent(input$toggle_balance, {
    if (show_balance()) {
      show_balance(FALSE)
    } else {
      request_pin("balance", "View Balance")
    }
  })

  output$balance_cards <- renderUI({
    acc <- my_account()
    balance_display <- if (show_balance()) {
      paste0("₹ ", format(round(acc$balance, 2), big.mark = ",", nsmall = 2))
    } else {
      "•••••••"
    }
    div(class = "card-row",
        div(class = "info-card",
            div(class = "info-icon", icon("wallet")),
            div(h4("Current Balance"),
                div(style = "display:flex; align-items:center; gap:12px;",
                    h2(balance_display),
                    actionLink("toggle_balance", icon(if (show_balance()) "eye-slash" else "eye"))
                ))
        ),
        div(class = "info-card",
            div(class = "info-icon", icon("id-card")),
            div(h4("Account Number"), h2(acc$acc_no))
        ),
        div(class = "info-card",
            div(class = "info-icon", icon("user")),
            div(h4("Account Holder"), h2(acc$full_name))
        )
    )
  })

  # ---------- DEPOSIT ----------
  observeEvent(input$btn_deposit, {
    req(current_user())
    if (is.na(input$deposit_amount) || input$deposit_amount <= 0) {
      output$deposit_msg <- renderText("Enter a valid amount.")
      return()
    }
    request_pin("deposit", "Deposit")
  })

  do_deposit <- function() {
    accounts <- read_accounts()
    idx <- which(accounts$acc_no == current_user())
    accounts$balance[idx] <- accounts$balance[idx] + input$deposit_amount
    write_accounts(accounts)
    log_transaction(current_user(), "Deposit", input$deposit_amount, accounts$balance[idx])
    output$deposit_msg <- renderText(paste("Deposited ₹", input$deposit_amount, "successfully."))
    bump()
  }

  # ---------- WITHDRAW ----------
  observeEvent(input$btn_withdraw, {
    req(current_user())
    if (is.na(input$withdraw_amount) || input$withdraw_amount <= 0) {
      output$withdraw_msg <- renderText("Enter a valid amount.")
      return()
    }
    request_pin("withdraw", "Withdraw")
  })

  do_withdraw <- function() {
    accounts <- read_accounts()
    idx <- which(accounts$acc_no == current_user())
    if (input$withdraw_amount > accounts$balance[idx]) {
      output$withdraw_msg <- renderText("Insufficient balance.")
      return()
    }
    accounts$balance[idx] <- accounts$balance[idx] - input$withdraw_amount
    write_accounts(accounts)
    log_transaction(current_user(), "Withdrawal", -input$withdraw_amount, accounts$balance[idx])
    output$withdraw_msg <- renderText(paste("Withdrew ₹", input$withdraw_amount, "successfully."))
    bump()
  }

  # ---------- TRANSFER: live recipient lookup ----------
  transfer_to_debounced <- debounce(reactive(input$transfer_to), 400)

  output$recipient_preview <- renderUI({
    acc_no <- transfer_to_debounced()
    if (is.null(acc_no) || nchar(trimws(acc_no)) == 0) return(NULL)
    accounts <- read_accounts()
    match_row <- accounts[accounts$acc_no == trimws(acc_no), ]
    if (trimws(acc_no) == current_user()) {
      div(class = "hint", style = "border-color:#e5484d; color:#e5484d;",
          icon("circle-exclamation"), " You can't transfer to your own account.")
    } else if (nrow(match_row) == 1) {
      div(class = "hint", style = "border-color:#1fae70;",
          icon("circle-check"), strong(" Sending to: "), match_row$full_name[1])
    } else {
      div(class = "hint", style = "border-color:#e5484d; color:#e5484d;",
          icon("circle-xmark"), " No account found with this number.")
    }
  })

  # ---------- TRANSFER: submit ----------
  observeEvent(input$btn_transfer, {
    req(current_user())
    to <- trimws(input$transfer_to)
    if (nchar(to) == 0) {
      output$transfer_msg <- renderText("Enter a recipient account number.")
      return()
    }
    if (to == current_user()) {
      output$transfer_msg <- renderText("You cannot transfer to your own account.")
      return()
    }
    accounts <- read_accounts()
    if (!(to %in% accounts$acc_no)) {
      output$transfer_msg <- renderText("Recipient account not found.")
      return()
    }
    if (is.na(input$transfer_amount) || input$transfer_amount <= 0) {
      output$transfer_msg <- renderText("Enter a valid amount.")
      return()
    }
    request_pin("transfer", "Transfer Money")
  })

  do_transfer <- function() {
    accounts <- read_accounts()
    from_idx <- which(accounts$acc_no == current_user())
    to        <- trimws(input$transfer_to)
    to_idx    <- which(accounts$acc_no == to)

    if (input$transfer_amount > accounts$balance[from_idx]) {
      output$transfer_msg <- renderText("Insufficient balance.")
      return()
    }

    recipient_name <- accounts$full_name[to_idx]
    accounts$balance[from_idx] <- accounts$balance[from_idx] - input$transfer_amount
    accounts$balance[to_idx]   <- accounts$balance[to_idx] + input$transfer_amount
    write_accounts(accounts)

    log_transaction(current_user(), "Transfer Sent", -input$transfer_amount,
                     accounts$balance[from_idx], note = paste("To", to))
    log_transaction(to, "Transfer Received", input$transfer_amount,
                     accounts$balance[to_idx], note = paste("From", current_user()))

    output$transfer_msg <- renderText(
      paste0("Sent ₹", input$transfer_amount, " to ", recipient_name, " (", to, ").")
    )
    updateTextInput(session, "transfer_to", value = "")
    bump()
  }

  # ---------- TABLE HELPERS ----------
  fmt_money <- function(x) format(round(x, 2), big.mark = ",", nsmall = 2, scientific = FALSE)

  badge_class <- function(type) {
    if (grepl("Deposit", type)) return("badge-deposit")
    if (grepl("Withdraw", type)) return("badge-withdraw")
    if (grepl("Transfer", type)) return("badge-transfer")
    return("badge-default")
  }

  style_tx <- function(tx) {
    tx$type    <- sprintf('<span class="badge-type %s">%s</span>', vapply(tx$type, badge_class, character(1)), tx$type)
    tx$amount  <- sprintf('<span class="%s">%s\u20b9 %s</span>',
                           ifelse(tx$amount >= 0, "amt-pos", "amt-neg"),
                           ifelse(tx$amount >= 0, "+", "-"),
                           fmt_money(abs(tx$amount)))
    tx$balance <- paste0("\u20b9 ", fmt_money(tx$balance))
    tx
  }

  # ---------- TABLES ----------
  output$overview_table <- renderTable({
    refresh_flag()
    req(current_user())
    tx <- read_transactions()
    tx <- tx[tx$acc_no == current_user(), c("type", "amount", "balance", "time")]
    tx <- tx[order(as.POSIXct(tx$time), decreasing = TRUE), ]
    tx <- head(tx, 5)
    tx <- style_tx(tx)
    names(tx) <- c("Type", "Amount", "Balance", "Time")
    tx
  }, sanitize.text.function = identity)

  output$history_table <- renderTable({
    refresh_flag()
    req(current_user())
    tx <- read_transactions()
    tx <- tx[tx$acc_no == current_user(), c("type", "amount", "balance", "note", "time")]
    tx <- tx[order(as.POSIXct(tx$time), decreasing = TRUE), ]
    tx <- style_tx(tx)
    names(tx) <- c("Type", "Amount", "Balance", "Note", "Time")
    tx
  }, sanitize.text.function = identity)
}

# ---------------------------------------------------------------
shinyApp(ui = ui, server = server)
