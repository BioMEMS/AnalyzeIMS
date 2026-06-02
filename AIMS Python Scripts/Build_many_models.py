import os
from pathlib import Path
import numpy as np
import pandas as pd

from sklearn.model_selection import StratifiedKFold, cross_validate
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.feature_selection import SelectKBest, SelectFromModel, f_classif, mutual_info_classif
from sklearn.linear_model import LogisticRegression
from sklearn.neighbors import KNeighborsClassifier
from sklearn.svm import SVC
from sklearn.ensemble import RandomForestClassifier, ExtraTreesClassifier, GradientBoostingClassifier
from matplotlib import pyplot as plt

# ---------------------------
# Config
# ---------------------------
DATA_PATH = r"C:\Users\Reid Honeycutt\Documents\DMS data test set"
FILE_GLOB = "*.xls"  # adjust if needed

# If you have a labels CSV, set this to a path. CSV must have columns: filename,label
LABELS_CSV = None

# If no labels CSV, infer from filenames using these tokens
LABEL_FROM_FILENAME = True
POSITIVE_TOKENS = ["pos", "positive"]
NEGATIVE_TOKENS = ["neg", "negative"]

# Data preprocessing options
DROP_HEADER_ROWS = 3  # set to 0 if not applicable
USE_TIME_WINDOW = True  # assumes first column is time
ROW_SLICE = None  # example: slice(200, 1000)
COL_SLICE = slice(1, None)  # drop first column (time); adjust if needed

# Feature selection
FEATURE_SELECTOR = "kbest"  # "kbest" or "model"
SELECT_METHOD = "mutual_info"  # "f_classif" or "mutual_info" (for kbest)
MODEL_SELECTOR = "log_reg_l1"  # "log_reg_l1" or "random_forest" (for model)
K_BEST = 20  # int or "all"

# Cross-validation
N_SPLITS = 9
RANDOM_STATE = 42


def _read_table(path: Path):
    if path.suffix.lower() in [".xls", ".xlsx"]:
        df = pd.read_excel(path, header=None)
        return df.to_numpy()
    return np.loadtxt(path, dtype=object, delimiter="\t")


def _to_float_matrix(arr):
    if isinstance(arr, np.ndarray) and arr.dtype != object:
        out = arr.astype(float, copy=False)
    else:
        df = pd.DataFrame(arr)
        out = df.apply(pd.to_numeric, errors="coerce").to_numpy(dtype=float)
    return np.nan_to_num(out, nan=0.0, posinf=0.0, neginf=0.0)


def _infer_label_from_name(name: str):
    low = name.lower()
    if any(tok in low for tok in POSITIVE_TOKENS):
        return 1
    if any(tok in low for tok in NEGATIVE_TOKENS):
        return 0
    return None


def _load_labels_csv(path: Path):
    df = pd.read_csv(path)
    if "filename" not in df.columns or "label" not in df.columns:
        raise ValueError("LABELS_CSV must have columns: filename,label")
    mapping = {str(r["filename"]): int(r["label"]) for _, r in df.iterrows()}
    return mapping


def _preprocess_gcdms(df: pd.DataFrame) -> pd.DataFrame:
    data = df.astype(float, copy=True)

    # Area-1 normalization per sample (column)
    col_sums = data.sum(axis=0)
    col_sums = col_sums.replace(0.0, np.nan)
    data = data.divide(col_sums, axis=1).fillna(0.0)

    # Log10 transform with small epsilon to avoid -inf
    eps = 1e-12
    data = np.log10(data.clip(lower=eps))

    # Pareto scaling per feature (row): divide by sqrt(std)
    row_std = data.std(axis=1, ddof=0)
    pareto_scale = np.sqrt(row_std).replace(0.0, np.nan)
    data = data.divide(pareto_scale, axis=0).fillna(0.0)

    # Mean-center per feature (row)
    row_mean = data.mean(axis=1)
    data = data.subtract(row_mean, axis=0)

    return data


def _preprocess_vitals(df: pd.DataFrame) -> pd.DataFrame:
    data = df.copy()
    num_cols = data.select_dtypes(include=[np.number]).columns.tolist()
    if "Patient ID" in num_cols:
        num_cols.remove("Patient ID")
    if not num_cols:
        return data

    subset = data[num_cols].astype(float)

    # Z-score normalization per feature (column)
    col_mean = subset.mean(axis=0)
    col_std = subset.std(axis=0, ddof=0).replace(0.0, np.nan)
    subset = subset.subtract(col_mean, axis=1).divide(col_std, axis=1).fillna(0.0)

    # Pareto scaling per feature (column): divide by sqrt(std)
    pareto_scale = np.sqrt(subset.std(axis=0, ddof=0)).replace(0.0, np.nan)
    subset = subset.divide(pareto_scale, axis=1).fillna(0.0)

    # Mean-center per feature (column)
    subset = subset.subtract(subset.mean(axis=0), axis=1)

    data[num_cols] = subset
    return data


def load_custom_dataset():
    data_path = Path(DATA_PATH)
    files = sorted(data_path.glob(FILE_GLOB))
    if not files:
        raise FileNotFoundError(f"No files found in {DATA_PATH} matching {FILE_GLOB}")

    label_map = _load_labels_csv(Path(LABELS_CSV)) if LABELS_CSV else None

    raw_tables = []
    for f in files:
        table = _read_table(f)
        if DROP_HEADER_ROWS and DROP_HEADER_ROWS > 0:
            table = table[DROP_HEADER_ROWS:, :]
        raw_tables.append(table)

    if USE_TIME_WINDOW:
        mins = [np.min(_to_float_matrix(t)[:, 0]) for t in raw_tables]
        maxs = [np.max(_to_float_matrix(t)[:, 0]) for t in raw_tables]
        window_min = np.max(mins)
        window_max = np.min(maxs)
    else:
        window_min = None
        window_max = None

    X_list = []
    y_list = []

    for f, table in zip(files, raw_tables):
        mat = _to_float_matrix(table)
        if USE_TIME_WINDOW:
            time_col = mat[:, 0]
            keep = np.logical_and(time_col >= window_min, time_col <= window_max)
            mat = mat[keep, :]
        if COL_SLICE is not None:
            mat = mat[:, COL_SLICE]
        if ROW_SLICE is not None:
            mat = mat[ROW_SLICE, :]
        mat = np.nan_to_num(mat, nan=0.0, posinf=0.0, neginf=0.0)
        X_list.append(mat.reshape(-1))

        if label_map is not None:
            label = label_map.get(f.name)
        elif LABEL_FROM_FILENAME:
            label = _infer_label_from_name(f.name)
        else:
            label = None

        if label is None:
            raise ValueError(f"Could not determine label for file: {f.name}")
        y_list.append(label)

    X = np.vstack(X_list)
    y = np.array(y_list, dtype=int)
    return X, y


def _build_scoring(y):
    classes = np.unique(y)
    if len(classes) == 2:
        return ["accuracy", "balanced_accuracy", "f1", "roc_auc"]
    return ["accuracy", "balanced_accuracy", "f1_macro"]


def _feature_selector(
    feature_selector=FEATURE_SELECTOR,
    select_method=SELECT_METHOD,
    model_selector=MODEL_SELECTOR,
    k_best=K_BEST,
):
    if feature_selector == "kbest":
        if select_method == "mutual_info":
            score_fn = mutual_info_classif
        else:
            score_fn = f_classif

        if k_best == "all":
            k = "all"
        else:
            k = int(k_best)
        return SelectKBest(score_func=score_fn, k=k)

    if model_selector == "random_forest":
        estimator = RandomForestClassifier(
            n_estimators=30,
            n_jobs=-1,
            random_state=RANDOM_STATE,
            class_weight="balanced",
        )
        threshold = "median"
    else:
        estimator = LogisticRegression(
            penalty="l1",
            solver="saga",
            max_iter=5000,
            n_jobs=-1,
            class_weight="balanced",
        )
        threshold = 1e-6

    max_features = None if k_best == "all" else int(k_best)
    return SelectFromModel(estimator=estimator, threshold=threshold, max_features=max_features)


def _make_pipeline(model, scale, selector=None):
    scaler = StandardScaler() if scale else "passthrough"
    selector = selector if selector is not None else _feature_selector()
    return Pipeline(
        [
            ("scaler", scaler),
            ("select", selector),
            ("model", model),
        ]
    )


def _small_sample_selector(n_samples, n_features):
    # Conservative univariate filtering for n << p
    k = min(n_features, max(10, min(50, n_samples * 2)))
    return _feature_selector(
        feature_selector="kbest",
        select_method="f_classif",
        k_best=k,
    )


def build_models(X):
    n_samples, n_features = X.shape
    small_n_high_p = n_samples < 50 and n_features > 500
    selector = _small_sample_selector(n_samples, n_features) if small_n_high_p else None

    models = []
    if small_n_high_p:
        models.append(("log_reg", _make_pipeline(
            LogisticRegression(
                penalty='elasticnet',
                l1_ratio=0.5,
                solver="saga",
                C=1,
                max_iter=8000,
                n_jobs=-1,
                class_weight="balanced",
            ),
            scale=True,
            selector=selector,
        )))
        models.append(("svm_lin", _make_pipeline(
            SVC(kernel="linear", C=1, probability=True, class_weight="balanced"),
            scale=True,
            selector=selector,
        )))
        models.append(("knn", _make_pipeline(
            KNeighborsClassifier(n_neighbors=3, weights="distance"),
            scale=True,
            selector=selector,
        )))
        models.append(("random_forest", _make_pipeline(
            RandomForestClassifier(
                n_estimators=30,
                max_depth=2,
                min_samples_leaf=2,
                max_features="sqrt",
                n_jobs=-1,
                random_state=RANDOM_STATE,
                class_weight="balanced",
            ),
            scale=False,
            selector=selector,
        )))
    else:
        models.append(("log_reg", _make_pipeline(
            LogisticRegression(l1_ratio=0.5, max_iter=5000, n_jobs=-1, class_weight="balanced"),
            scale=True
        )))
        models.append(("knn", _make_pipeline(
            KNeighborsClassifier(n_neighbors=4, leaf_size=20, n_jobs=-1, weights="distance"),
            scale=True
        )))
        models.append(("svm_lin", _make_pipeline(
            SVC(kernel="rbf", probability=True, class_weight="balanced"),
            scale=True
        )))
        models.append(("random_forest", _make_pipeline(
            RandomForestClassifier(n_estimators=20, n_jobs=-1, max_depth=1,random_state=RANDOM_STATE),
            scale=False
        )))
    # models.append(("extra_trees", _make_pipeline(
    #     ExtraTreesClassifier(n_estimators=20, n_jobs=-1, max_depth=1, random_state=RANDOM_STATE),
    #     scale=False
    # )))
    # models.append(("gradient_boosting", _make_pipeline(
    #     GradientBoostingClassifier(random_state=RANDOM_STATE),
    #     scale=False
    # )))

    try:

        from xgboost import XGBClassifier
        models.append(("xgboost", _make_pipeline(
            XGBClassifier(
                n_estimators=20,
                max_depth=1,
                learning_rate=0.1,
                subsample=0.8,
                colsample_bytree=0.8,
                eval_metric="logloss",
                random_state=RANDOM_STATE,
                n_jobs=-1,
            ),
            scale=False
        )))
    except Exception:
        print("xgboost not available; skipping.")

    return models


def evaluate_models(X, y):
    cv = StratifiedKFold(n_splits=N_SPLITS, shuffle=True, random_state=RANDOM_STATE)
    scoring = _build_scoring(y)

    results = []
    for name, pipeline in build_models(X):
        try:
            scores = cross_validate(
                pipeline,
                X,
                y,
                cv=cv,
                scoring=scoring,
                n_jobs=-1,
                error_score="raise",
                return_train_score=False,
            )
            summary = {"model": name}
            for metric in scoring:
                key = f"test_{metric}"
                summary[f"{metric}_mean"] = float(np.mean(scores[key]))
                summary[f"{metric}_std"] = float(np.std(scores[key]))
            results.append(summary)
        except Exception as e:
            results.append({"model": name, "error": str(e)})

    return results


def results_to_df(results):
    ok = [r for r in results if "error" not in r]
    err = [r for r in results if "error" in r]

    rows = []
    if ok:
        ok_sorted = ok #sorted(ok, key=lambda r: r.get("accuracy_mean", 0.0), reverse=True)
        for r in ok_sorted:
            row = {
                "Model": r["model"],
                "Accuracy_mean": r.get("accuracy_mean", 0.0),
                "Accuracy_std": r.get("accuracy_std", 0.0),
                "Balanced Accuracy_mean": r.get("balanced_accuracy_mean", 0.0),
                "Balanced Accuracy_std": r.get("balanced_accuracy_std", 0.0),
                "F1 Accuracy_mean": r.get("f1_mean", r.get("f1_macro_mean", 0.0)),
                "F1 Accuracy_std": r.get("f1_std", r.get("f1_macro_std", 0.0)),
            }
            if "roc_auc_mean" in r:
                row["ROC AUC_mean"] = r.get("roc_auc_mean", 0.0)
                row["ROC AUC_std"] = r.get("roc_auc_std", 0.0)
            rows.append(row)
    if err:
        for r in err:
            rows.append({"model": r["model"], "error": r["error"]})

    return pd.DataFrame(rows)


def print_results_table(df, title):
    print(f"\n{title}")
    if df.empty:
        print("(no results)")
        return
    df = df.copy()
    mean_cols = [c for c in df.columns if c.endswith("_mean")]
    for mean_col in mean_cols:
        base = mean_col[:-5]
        std_col = f"{base}_std"
        if std_col in df.columns:
            df[base] = [
                f"{m:.2f}±{s:.2f}" if pd.notna(m) and pd.notna(s) else ""
                for m, s in zip(df[mean_col], df[std_col])
            ]
    drop_cols = [c for c in df.columns if c.endswith("_mean") or c.endswith("_std")]
    df = df.drop(columns=drop_cols, errors="ignore")
    df.to_clipboard()
    print(df.to_csv(sep="\t", index=False))

GC_DMS_metadata =  pd.read_excel('C:\\Users\\Reid Honeycutt\\Documents\\U01 NIH Update\\March 2026\\20260309_PeakTable_forREID.xlsx', sheet_name='Samples Info', header=1)
GC_DMS_Data = pd.read_excel('C:\\Users\\Reid Honeycutt\\Documents\\U01 NIH Update\\March 2026\\20260309_PeakTable_forREID.xlsx', sheet_name='Final by RATIO', header=2)
#GC_DMS_Data = pd.read_excel('C:\\Users\\Reid Honeycutt\\Documents\\U01 Asthma Study\\Updated Data\\20260121_NIHU01_EBVdata_Final.xlsx', sheet_name='Final Data', header=3)
Vitals_Data = pd.read_csv('C:\\Users\\Reid Honeycutt\\Documents\\U01 NIH Update\\March 2026\\Vitals_Data_Processed_3_26.csv', header=0)


conditions = ['Asthma', 'ADHD', 'Eczema', 'Osteoarthritis']
#conditions_columns = GC_DMS_metadata.drop(GC_DMS_metadata.filter(regex='(?i)Unnamed'), axis=1)


if __name__ == "__main__":
    Vitals_Data_nums = [int(x.split('_')[0]) for x in list(Vitals_Data['Patient ID'])]
    Vitals_Data['Patient ID'] = Vitals_Data_nums
    Vitals_Data.sort_values(by=['Patient ID'], inplace=True)
    for condition in conditions:
        condition_rows = GC_DMS_metadata.iloc[GC_DMS_metadata[GC_DMS_metadata[condition] != 0].index]
        control_rows = GC_DMS_metadata.iloc[GC_DMS_metadata[GC_DMS_metadata['Control'] != 0].index]

        condition_subjects = condition_rows['Skin']
        condition_subjects = list(set(GC_DMS_Data.columns).intersection(condition_subjects))
        control_subjects = control_rows['Skin']
        control_subjects = list(set(GC_DMS_Data.columns).intersection(control_subjects))

        condition_gcdms_data = GC_DMS_Data[condition_subjects].iloc[4:,:]
        control_gcdms_data = GC_DMS_Data[control_subjects].iloc[4:, :]
        # condition_gcdms_data = GC_DMS_Data[condition_subjects].iloc[12:,:]
        # control_gcdms_data = GC_DMS_Data[control_subjects].iloc[12:, :]

        # condition_gcdms_data = _preprocess_gcdms(condition_gcdms_data)
        # control_gcdms_data = _preprocess_gcdms(control_gcdms_data)

        control_subjects_nums = [int(x.strip('S').lstrip('0')) for x in list(control_subjects)]
        condition_subjects_nums = [int(x.strip('S').lstrip('0')) for x in list(condition_subjects)]

        vitals_nums = list(Vitals_Data['Patient ID'])
        vitals_nums = np.array(vitals_nums)

        control_inds = np.isin(vitals_nums.astype(int), control_subjects_nums)
        condition_inds = np.isin(vitals_nums.astype(int), condition_subjects_nums)

        control_vitals = Vitals_Data.iloc[control_inds]
        condition_vitals = Vitals_Data.iloc[condition_inds]

        # control_vitals = _preprocess_vitals(control_vitals)
        # condition_vitals = _preprocess_vitals(condition_vitals)

        condition_col_names = [int(x.strip('S').lstrip('0')) for x in list(condition_gcdms_data.columns)]
        condition_gcdms_data.columns = condition_col_names
        condition_gcdms_data.sort_index(axis=1, inplace=True)
        condition_gcdms_data = condition_gcdms_data.T
        condition_gcdms_data = condition_gcdms_data.loc[list(condition_vitals['Patient ID']), :]

        control_col_names = [int(x.strip('S').lstrip('0')) for x in list(control_gcdms_data.columns)]
        control_gcdms_data.columns = control_col_names
        control_gcdms_data.sort_index(axis=1, inplace=True)
        control_gcdms_data = control_gcdms_data.T
        control_gcdms_data = control_gcdms_data.loc[list(control_vitals['Patient ID']), :]

        condition_arr = np.concatenate([np.array(condition_vitals)[:,1:-2], np.array(condition_gcdms_data)], axis=1)
        control_arr = np.concatenate([np.array(control_vitals)[:,1:-2], np.array(control_gcdms_data)], axis=1)
        X = np.concatenate([condition_arr, control_arr], axis=0)
        X = np.nan_to_num(X.astype(float), nan=np.nanmean(X), posinf=np.nanmean(X), neginf=np.nanmean(X))

        condition_col = GC_DMS_metadata[condition]
        metadata_nums = [int(x.strip('S').lstrip('0')) for x in list(GC_DMS_metadata['Skin'])]
        patient_nums = list(condition_vitals['Patient ID']) + list(control_vitals['Patient ID'])
        pateint_locs = np.isin(np.array(metadata_nums), patient_nums)
        y = np.array(condition_col[pateint_locs])

        #X, y = load_custom_dataset()
        results = evaluate_models(X, y)
        df = results_to_df(results)
        df.to_clipboard()
        print_results_table(df, f"Condition: {condition}")
        print('pause')


print('pause')
