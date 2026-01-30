## How to Run the Project

1. Clone the repository or download it as a ZIP file from GitHub.
2. Open the project by double-clicking the `.Rproj` file (optional but recommended).
3. In RStudio, run the following scripts sequentially from the project root:

```r
source("src/01_load_data.R")
source("src/02_build_features.R")
source("src/03_train_eval_team.R")
All scripts are designed to run from the repository root without manual path adjustments.

Each script includes a DEBUG switch that controls the verbosity of intermediate outputs.


# NBA Match Outcome Prediction (R)

This project focuses on predicting the outcome of an NBA game **before the game is played**, using only **pre-game information** derived from teams’ recent performances.

The core idea is to move away from post-game explanation models and instead build a **forecasting-oriented pipeline**, similar to the logic used in legal betting, fantasy sports platforms, and sports analytics products.

All modeling decisions are intentionally conservative and interpretable, prioritizing **realistic usage and reproducibility** over overfitted accuracy.

---

## Motivation & Context

In the data-driven decision-making era, sports analytics has become an important tool not only for teams and coaches, but also for fans, bettors, and businesses. Among all major sports, the NBA stands out due to its fast-paced structure and extremely rich statistical ecosystem, making it a strong candidate for predictive modeling.

The goal of this project is to answer questions such as:

- What are the chances that Boston beats Milwaukee tonight based on their last five games?
- Which team-level performance indicators have the strongest relationship with winning?
- Can a simple and interpretable model produce meaningful predictions using only pre-game data?

This approach mirrors the basic logic behind how odds are set in the legal betting industry, where only information known before tip-off can be used.

Beyond betting, such a framework can also support fans, fantasy players, and sports content platforms by providing data-driven insights rather than opinion-based judgment.

---

## Data Collection

The original data source is [basketball-reference.com](https://www.basketball-reference.com/), one of the most reliable archives for NBA statistics.

The raw dataset is player-level and includes both basic and advanced box score metrics for each game. To make the data suitable for modeling, we use a **team-level version** of this dataset, created by an open-source contributor. In this version:

- Some metrics are aggregated as totals (e.g. rebounds, shot attempts)
- Some metrics are averaged (e.g. FG%, FT%)
- Some metrics capture maximum player performance (e.g. max points, max FG%)

The dataset is hosted on GitHub and pulled directly via URL to ensure reproducibility and fast setup.

Each row represents **one team in one game**, regardless of home or away status.

---

## Feature Engineering & Planning

### Rolling Team Form (Last 5 Games)

To reflect short-term momentum rather than long-run averages, the main features are constructed using **rolling averages over the last 5 games**.

For each team and each game:
- Only matches **played before that date** are used
- The previous 5 games are averaged
- This avoids any form of future information leakage

These features capture temporary form, which is crucial in a dynamic league like the NBA.

---

### Opponent-Aware Features

One of the most challenging and important parts of the project is incorporating **opponent strength**.

For each game:
- The opponent team is identified
- That opponent’s own lag-5 statistics are fetched
- The opponent’s features are appended with an `_opp` suffix

This allows the model to compare:
- our team’s recent form
- against the opponent’s recent form
on the **same match date**.

---

## Data Visualization & Feature Selection

Before modeling, extensive exploratory analysis is performed.

- Only numeric variables are considered
- Correlations with the target variable (`won`) are computed
- Only `_lag5` variables are analyzed, as these represent pre-game information

A correlation bar plot is used to visualize the strength and direction of relationships.

While no single variable shows a very strong correlation, several features fall into a moderate predictive range (approximately ±0.08 to ±0.20). These features are selected for modeling.

This step ensures:
- interpretability
- reduced noise
- controlled model complexity

---

## Modeling Strategy

### Train–Test Split

For each team:
- Data is split into 70% training and 30% test sets
- Stratified sampling is used to maintain win/loss balance

### Baseline Model: Logistic Regression

Logistic regression is chosen as the baseline model because:
- It is interpretable
- It is robust for binary classification
- It avoids unnecessary complexity for the given problem

Two models are trained for each team:
1. Using all selected features
2. Removing highly correlated features (correlation > 0.7) to reduce multicollinearity

---

## Evaluation Metrics

Model performance is evaluated using:
- **Accuracy**: proportion of correctly predicted games
- **AUC (Area Under the ROC Curve)**: ability to rank wins above losses across thresholds

Both metrics are necessary:
- Accuracy alone can be misleading
- AUC captures overall discrimination power

---

## Results

Example results for Boston Celtics and Milwaukee Bucks:

- **Accuracy**: approximately 61%–62%
- **AUC**: approximately 0.60–0.62

These results are meaningful given that:
- Only pre-game data is used
- No betting odds, injuries, or contextual features are included
- The NBA inherently contains high randomness

The model clearly performs better than random guessing and captures real signals from recent team performance.

---

## Conclusions

This project demonstrates that:

- A team’s performance over the last 5 games is a useful indicator of short-term outcomes
- Even a simple and interpretable model can reach reasonable predictive performance
- Team-level modeling provides a clean and manageable abstraction

While the model is intentionally simple, it serves as a strong foundation.

---

## Potential Improvements

- Incorporating home/away effects
- Adding schedule density or travel fatigue
- Including player availability or injury proxies
- Testing more advanced models (Random Forest, XGBoost)
- Segmenting analysis by season or playoff stage

---

## Business Use Cases

With further development, this model can support:

**Sports Betting Platforms**
- Assisting in pre-game odds generation
- Identifying mispriced matchups
- Supporting decision systems

**Fantasy Sports Applications**
- Helping users evaluate team strength
- Providing data-driven pre-game insights

**Sports Media & Content**
- Pre-game prediction visuals
- Interactive dashboards
- Statistical storytelling

**Sports Analytics Education**
- Entry-level scouting tools
- Training material for junior analysts

---

## Reproducibility & Debug Mode

Each script includes a `DEBUG` switch:

```r
DEBUG <- TRUE

TRUE: shows intermediate outputs and visual checks

FALSE: runs silently in production mode

All scripts can be executed sequentially from the repository root.

## Notes

This project prioritizes:

- realistic forecasting

- transparent feature construction

- careful handling of temporal data

- clarity over overfitting
