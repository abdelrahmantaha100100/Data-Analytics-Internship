import pandas as pd

df = pd.read_csv(r"data/train.csv")
print("raw:", df.shape)

df["Order Date"] = pd.to_datetime(df["Order Date"], dayfirst=True)
df["Ship Date"] = pd.to_datetime(df["Ship Date"], dayfirst=True)

print("missing postal codes:", df["Postal Code"].isna().sum())
df.loc[(df["City"] == "Burlington") & (df["State"] == "Vermont"), "Postal Code"] = 5401
df["Postal Code"] = df["Postal Code"].astype(int).astype(str).str.zfill(5)

before = len(df)
df = df.drop_duplicates(subset=[c for c in df.columns if c != "Row ID"])
print("duplicates removed:", before - len(df))

df["Ship Days"] = (df["Ship Date"] - df["Order Date"]).dt.days
df["Order Year"] = df["Order Date"].dt.year
df["Order Month"] = df["Order Date"].dt.to_period("M").dt.to_timestamp()
df["Sales"] = df["Sales"].round(2)

df.to_csv(r"data/superstore_clean.csv", index=False, date_format="%Y-%m-%d")
print("clean:", df.shape)
print("missing values left:", df.isnull().sum().sum())
print("total sales:", round(df["Sales"].sum(), 2))
