# 🏦 Personal Banking System (R Shiny)

A single-page web application for managing a personal bank account — register, log in, deposit, withdraw, transfer funds, and view transaction history — all built with **R** and the **Shiny** web framework.

## ✨ Features

- **Attractive landing page** with a hero banner, feature highlights, and a login/register card
- **User registration & login** (stored locally, no external database needed)
- **Live dashboard** with balance, account number, and account holder cards
- **Deposit / Withdraw / Transfer** money between accounts
- **Full transaction history** with running balance
- Clean custom CSS (no Bootstrap-default look)

## 🖥️ Tech Stack

- [R](https://www.r-project.org/)
- [Shiny](https://shiny.posit.co/)
- [shinyjs](https://deanattali.com/shinyjs/) (for panel switching / hide-show effects)
- Plain CSS + [Font Awesome](https://fontawesome.com/) icons

## 📦 Installation

1. Install R (≥ 4.0) from [r-project.org](https://cran.r-project.org/).
2. Install the required packages:

   ```r
   install.packages(c("shiny", "shinyjs"))
   ```

3. Clone this repository:

   ```bash
   git clone https://github.com/<your-username>/personal-banking-system.git
   cd personal-banking-system
   ```

4. Run the app:

   ```r
   shiny::runApp()
   ```

   Or from a terminal:

   ```bash
   Rscript -e "shiny::runApp('.', launch.browser = TRUE)"
   ```

## 🔑 Demo Login

A demo account is created automatically the first time the app runs:

| Username | Password |
|----------|----------|
| `demo`   | `demo123` |

## 📁 Project Structure

```
personal-banking-system/
├── app.R              # UI + server logic (single-file Shiny app)
├── www/
│   └── style.css       # Custom styling for the landing page & dashboard
├── accounts.rds         # Auto-generated local "database" of accounts
├── transactions.rds      # Auto-generated local transaction ledger
└── README.md
```

> `accounts.rds` and `transactions.rds` are created automatically on first run and are ignored by git (see `.gitignore`) so every clone starts fresh with just the demo account.

## 🚀 Deploying

You can deploy this app for free on [shinyapps.io](https://www.shinyapps.io/) or self-host it on any server with R + Shiny Server installed.

## 📌 Notes / Possible Extensions

- Passwords are stored in plain text for simplicity — for a production system, hash them (e.g. with `sodium` or `bcrypt`).
- Data is stored in local `.rds` files — swap in a real database (SQLite/PostgreSQL via `DBI`) for multi-user, concurrent-safe production use.
- Ideas to extend: interest calculation, monthly statements (PDF export), spending charts (`ggplot2`/`plotly`), admin panel.

## 📄 License

MIT — feel free to use this project for learning or as a portfolio piece.
