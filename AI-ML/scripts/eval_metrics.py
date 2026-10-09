import pandas as pd
import numpy as np
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, classification_report
from hawa_ml.settings import settings
from hawa_ml.forecasting.features import prepare_multi_horizon_dataset
from hawa_ml.attribution.classifier import generate_weak_proxy_labels, SOURCE_CLASSES
import lightgbm as lgb

data_path = settings.PROCESSED_DATA_DIR / 'stations_hourly.parquet'
df = pd.read_parquet(data_path)

print("=" * 80)
print(" 1. SOURCE ATTRIBUTION MULTI-CLASS CLASSIFIER (LightGBM)")
print("=" * 80)

df_labeled = generate_weak_proxy_labels(df)
df_labeled['hour'] = df_labeled['timestamp'].dt.hour
df_labeled['month'] = df_labeled['timestamp'].dt.month
df_labeled['ratio_pm25_pm10'] = df_labeled['pm25'] / np.maximum(df_labeled['pm10'], 1e-4)

feature_cols = ['pm25', 'pm10', 'ratio_pm25_pm10', 'no2', 'co', 'so2', 'hour', 'month', 'temperature', 'humidity', 'wind_speed']
for c in feature_cols:
    if c in df_labeled.columns:
        df_labeled[c] = df_labeled[c].fillna(df_labeled[c].median())

# Temporal 80/20 split
df_sorted = df_labeled.sort_values('timestamp').reset_index(drop=True)
split_idx = int(len(df_sorted) * 0.8)
test_df = df_sorted.iloc[split_idx:]

X_test = test_df[feature_cols].values
y_test = test_df['weak_label'].values

model_path = settings.MODELS_DIR / 'attribution_classifier.txt'
booster = lgb.Booster(model_file=str(model_path))
preds_prob = booster.predict(X_test)
y_pred = np.argmax(preds_prob, axis=1)

acc = accuracy_score(y_test, y_pred)
prec_macro = precision_score(y_test, y_pred, average='macro', zero_division=0)
rec_macro = recall_score(y_test, y_pred, average='macro', zero_division=0)
f1_macro = f1_score(y_test, y_pred, average='macro', zero_division=0)

prec_weighted = precision_score(y_test, y_pred, average='weighted', zero_division=0)
rec_weighted = recall_score(y_test, y_pred, average='weighted', zero_division=0)
f1_weighted = f1_score(y_test, y_pred, average='weighted', zero_division=0)

print(f"Evaluated on {len(test_df)} held-out temporal observations:")
print(f"Overall Accuracy:           {acc * 100:.2f}%")
print(f"Precision (Weighted):       {prec_weighted * 100:.2f}% | Precision (Macro): {prec_macro * 100:.2f}%")
print(f"Recall (Weighted):          {rec_weighted * 100:.2f}% | Recall (Macro):    {rec_macro * 100:.2f}%")
print(f"F1-Score (Weighted):        {f1_weighted:.4f} ({f1_weighted * 100:.2f}%) | F1-Score (Macro):  {f1_macro:.4f}")
print("\nPer-Class Breakdown:")
target_names = [sc.value for sc in SOURCE_CLASSES]
print(classification_report(y_test, y_pred, target_names=target_names, zero_division=0))

print("=" * 80)
print(" 2. 72-HOUR FORECASTER: CAQM GRAP ALERT BREACH CLASSIFICATION")
print("=" * 80)
print("Binary Task: Predicting CAQM Severe Pollution Alert Trigger (Actual PM2.5 >= 150 ug/m3)")

horizons = [1, 3, 6, 12, 24, 48, 72]
full_df, feat_cols, target_cols = prepare_multi_horizon_dataset(df, horizons=horizons)
full_df = full_df.sort_values('timestamp').reset_index(drop=True)
split_idx_f = int(len(full_df) * 0.8)
test_feat_df = full_df.iloc[split_idx_f:]

print(f"{'Horizon':<8} | {'Accuracy':<10} | {'Precision':<10} | {'Recall':<10} | {'F1-Score':<10} | {'MAE (ug/m3)':<12}")
print("-" * 70)

for h in horizons:
    model_file = settings.MODELS_DIR / f'lgb_pm25_{h}h_p50.txt'
    if not model_file.exists():
        continue
    booster_f = lgb.Booster(model_file=str(model_file))
    
    target_col = f"target_pm25_{h}h"
    valid_mask = test_feat_df[target_col].notna() & test_feat_df[feat_cols].notna().all(axis=1)
    sub_df = test_feat_df[valid_mask]
    
    X_test_f = sub_df[feat_cols].values
    y_true_cont = sub_df[target_col].values
    y_pred_cont = booster_f.predict(X_test_f)
    
    threshold = 150.0  # CAQM Severe Level PM2.5 threshold
    y_true_bin = (y_true_cont >= threshold).astype(int)
    y_pred_bin = (y_pred_cont >= threshold).astype(int)
    
    acc_h = accuracy_score(y_true_bin, y_pred_bin)
    prec_h = precision_score(y_true_bin, y_pred_bin, zero_division=0)
    rec_h = recall_score(y_true_bin, y_pred_bin, zero_division=0)
    f1_h = f1_score(y_true_bin, y_pred_bin, zero_division=0)
    mae_h = np.mean(np.abs(y_true_cont - y_pred_cont))
    
    print(f"{str(h)+'h':<8} | {acc_h * 100:6.2f}%    | {prec_h * 100:6.2f}%    | {rec_h * 100:6.2f}%    | {f1_h:8.4f}   | {mae_h:6.2f}")

print("=" * 80)
