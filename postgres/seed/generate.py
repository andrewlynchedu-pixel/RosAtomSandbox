#!/usr/bin/env python3
"""
Генератор учебной базы АЭС (~90-110k строк).
Только стандартная библиотека Python — pip install не нужен.

Запуск:
    python generate.py
    -> создаёт CSV в ./data/

Сценарий года 2025:
- Блок-1 (ВВЭР-1000): ППР 01.07-30.07.2025 (мощность 0), перегрев 10-12.03, вибрация 05.08
- Блок-2 (ВВЭР-1200): стабильная работа, кратковременный сброс мощности 15-16.10
- 80 сотрудников, график 2/2 для сменного персонала
"""
import csv
import random
from datetime import datetime, date, time, timedelta
from pathlib import Path

RANDOM_SEED = 42
random.seed(RANDOM_SEED)

OUT = Path(__file__).parent / "data"
OUT.mkdir(parents=True, exist_ok=True)

YEAR = 2025
START = datetime(YEAR, 1, 1, 0, 0, 0)
END = datetime(YEAR, 12, 31, 22, 0, 0)

PPR_START = date(YEAR, 7, 1)
PPR_END = date(YEAR, 7, 30)

OVERHEAT_START = datetime(YEAR, 3, 10, 0, 0)
OVERHEAT_END = datetime(YEAR, 3, 12, 23, 59)

VIBRATION_DAY = date(YEAR, 8, 5)
POWER_DIP_START = datetime(YEAR, 10, 15)
POWER_DIP_END = datetime(YEAR, 10, 16, 23)


def gauss(mu, sigma):
    return random.gauss(mu, sigma)


# ---------- 1. EMPLOYEES (80) ----------
first_names_m = ["Алексей", "Дмитрий", "Сергей", "Игорь", "Андрей", "Владимир", "Николай", "Павел", "Роман", "Олег"]
first_names_f = ["Анна", "Елена", "Ольга", "Наталья", "Ирина", "Марина", "Светлана", "Татьяна"]
last_names = ["Иванов", "Петров", "Сидоров", "Кузнецов", "Смирнов", "Попов", "Соколов", "Михайлов", "Федоров", "Морозов",
              "Волков", "Лебедев", "Козлов", "Новиков", "Павлов", "Семенов", "Голубев", "Виноградов", "Богданов", "Воробьев"]
positions_by_dept = {
    1: ["ВИУР", "ВИУБ", "НС РЦ", "Оператор РО", "Слесарь РО"],
    2: ["НСТЦ", "Машинист-обходчик", "Слесарь ТЦ", "ВИУТ"],
    3: ["ДЭМ", "Электрослесарь", "НС ЭЦ"],
    4: ["Инженер ТАИ", "Слесарь КИПиА", "НС ЦТАИ"],
    5: ["Аппаратчик ХЦ", "Лаборант", "НС ХЦ"],
    6: ["Инженер ОЯБиН", "Физик", "НС ОЯБиН"],
}

employees = []
eid = 1
for dept_id in range(1, 7):
    n = 14 if dept_id <= 4 else 12  # 14*4 + 12*2 = 80
    for _ in range(n):
        is_f = random.random() < 0.25
        ln = random.choice(last_names)
        if is_f:
            ln = ln + "а"
            fn = random.choice(first_names_f)
            mn = random.choice(["Александровна", "Дмитриевна", "Сергеевна", "Игоревна", "Андреевна"])
        else:
            fn = random.choice(first_names_m)
            mn = random.choice(["Александрович", "Дмитриевич", "Сергеевич", "Игоревич", "Андреевич"])
        pos = random.choice(positions_by_dept[dept_id])
        hire = date(random.randint(2005, 2023), random.randint(1, 12), random.randint(1, 28))
        skill = random.randint(2, 5) if "НС" in pos or "ВИУ" in pos or "Инженер" in pos else random.randint(1, 4)
        salary = random.randint(90_000, 220_000) if skill >= 4 else random.randint(60_000, 130_000)
        employees.append([eid, f"{ln} {fn} {mn}", dept_id, pos, hire.isoformat(), skill, salary])
        eid += 1

with open(OUT / "employees.csv", "w", newline="", encoding="utf-8") as f:
    csv.writer(f).writerows(employees)
print(f"employees: {len(employees)}")

# ---------- 2. SENSOR_READINGS (каждые 2 часа, 14 датчиков) ----------
# sensor_id -> (base, sigma, type)
sensor_cfg = {
    1:  (305.0, 2.5, "temp"), 2: (305.0, 2.5, "temp"),
    3:  (308.0, 2.0, "temp"), 4: (308.0, 2.0, "temp"),
    5:  (15.7, 0.15, "press"), 6: (16.0, 0.12, "press"),
    7:  (98.0, 2.0, "flux"), 8: (99.0, 1.5, "flux"),
    9:  (2.1, 0.5, "vib"), 10: (1.8, 0.4, "vib"),
    11: (10.0, 0.3, "level"), 12: (10.2, 0.25, "level"),
    13: (48.0, 2.0, "oil"), 14: (46.0, 1.8, "oil"),
}
# датчики блока-1: 1,2,5,7,9,11,13 — зависят от ППР

def in_ppr(dt):
    return PPR_START <= dt.date() <= PPR_END

readings = []
ts = START
while ts <= END:
    for sid, (base, sigma, kind) in sensor_cfg.items():
        v = gauss(base, sigma)
        # суточная волна
        v += 1.2 * __import__("math").sin(2 * __import__("math").pi * ts.hour / 24)
        # ППР: блок-1 остывает, давление падает, поток 0
        if in_ppr(ts) and sid in (1, 2, 5, 7, 9, 11, 13):
            if kind == "temp":
                v = gauss(45, 5)
            elif kind == "press":
                v = gauss(2.0, 0.5)
            elif kind == "flux":
                v = gauss(0.5, 0.5)
            elif kind == "vib":
                v = abs(gauss(0.3, 0.2))
        # аномалия: перегрев блока-1 10-12 марта (+22 градуса на temp)
        if OVERHEAT_START <= ts <= OVERHEAT_END and sid in (1, 2):
            v += gauss(22, 3)
        # аномалия: вибрация 5 августа на обоих турбинах
        if ts.date() == VIBRATION_DAY and sid in (9, 10):
            v += abs(gauss(4.5, 1.0))
        # небольшой сброс в октябре для блока-2 temp
        if POWER_DIP_START <= ts <= POWER_DIP_END and sid in (3, 4):
            v -= gauss(8, 1.5)
        v = round(max(v, 0), 2)
        quality = 1
        if random.random() < 0.002:
            quality = 2  # недостоверно
            v = round(v * random.uniform(1.5, 2.5), 2)
        elif random.random() < 0.003:
            quality = 0  # пропуск/обрыв
        readings.append([ts.strftime("%Y-%m-%d %H:%M:%S"), sid, v, quality])
    ts += timedelta(hours=2)

with open(OUT / "sensor_readings.csv", "w", newline="", encoding="utf-8") as f:
    csv.writer(f).writerows(readings)
print(f"sensor_readings: {len(readings)}")

# ---------- 3. POWER_GENERATION (почасово, блок-1) ----------
gen = []
ts = datetime(YEAR, 1, 1, 0, 0, 0)
while ts <= datetime(YEAR, 12, 31, 23, 0, 0):
    plan = 1000.0
    if ts.month in (1, 2, 12):
        plan = 1000.0
    elif ts.month in (6, 7, 8):
        plan = 950.0
    # ППР — 0
    if in_ppr(ts):
        power = 0.0
    elif OVERHEAT_START <= ts <= OVERHEAT_END:
        power = round(gauss(820, 25), 1)  # разгрузка при перегреве
    elif POWER_DIP_START <= ts <= POWER_DIP_END:
        power = round(gauss(600, 40), 1)
    else:
        power = round(max(0, gauss(plan - 15, 20)), 1)
    gen.append([ts.strftime("%Y-%m-%d %H:%M:%S"), 1, power, plan])
    ts += timedelta(hours=1)

with open(OUT / "power_generation.csv", "w", newline="", encoding="utf-8") as f:
    csv.writer(f).writerows(gen)
print(f"power_generation: {len(gen)}")

# ---------- 4. ALARMS (~ связанные с аномалиями + фон) ----------
alarms = []
aid = 1

def add_alarm(ts_, sid, unit, sev, msg):
    global aid
    ack = random.randint(1, 80) if sev != "info" and random.random() < 0.9 else ""
    res = (ts_ + timedelta(hours=random.randint(1, 30))).strftime("%Y-%m-%d %H:%M:%S") if ack else ""
    alarms.append([aid, ts_.strftime("%Y-%m-%d %H:%M:%S"), sid, unit, sev, msg, ack, res])
    aid += 1

# перегрев: критические каждые 4 часа
t = OVERHEAT_START
while t <= OVERHEAT_END:
    add_alarm(t, random.choice([1, 2]), 1, "critical", "Температура 1 контура выше 320°C")
    t += timedelta(hours=4)
# вибрация
for h in (2, 8, 14, 20):
    add_alarm(datetime.combine(VIBRATION_DAY, time(h, 0)), random.choice([9, 10]), random.choice([1, 2]), "warning", "Вибрация подшипника турбины выше 4.5 мм/с")
# сброс мощности октябрь
t = POWER_DIP_START
while t <= POWER_DIP_END:
    add_alarm(t, 3, 2, "warning", "Снижение нейтронного потока, разгрузка блока")
    t += timedelta(hours=8)
# ППР информационные
d = PPR_START
while d <= PPR_END:
    if random.random() < 0.4:
        add_alarm(datetime.combine(d, time(9, 0)), "", 1, "info", "ППР: работы на системе САОЗ по графику")
    d += timedelta(days=1)
# фон: случайные ~1500 info/warning за год
for _ in range(1500):
    rts = datetime(YEAR, 1, 1) + timedelta(hours=random.randint(0, 365 * 24), minutes=random.randint(0, 59))
    sev = random.choices(["info", "warning", "critical"], weights=[80, 18, 2])[0]
    sid = random.randint(1, 14)
    unit = 1 if sid in (1, 2, 5, 7, 9, 11, 13) else 2
    msg = random.choice([
        "Отклонение параметра в пределах предупредительной уставки",
        "Кратковременная потеря качества сигнала датчика",
        "Небольшое превышение уставки по давлению",
        "Плановое опробование канала безопасности",
        "Вибрация в норме, диагностическое сообщение",
    ])
    add_alarm(rts, sid, unit, sev, msg)

alarms.sort(key=lambda r: r[1])
# перенумеровать id после сортировки
for i, r in enumerate(alarms, 1):
    r[0] = i

with open(OUT / "alarms.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    for r in alarms:
        # пустые ack/sid -> NULL для COPY (пишем \N)
        row = [r[0], r[1], (r[2] if r[2] != "" else "\\N"), r[3], r[4], r[5],
               (r[6] if r[6] != "" else "\\N"), (r[7] if r[7] != "" else "\\N")]
        w.writerow(row)
print(f"alarms: {len(alarms)}")

# ---------- 5. MAINTENANCE (~40) ----------
maint = []
mid = 1
# главный ППР
maint.append([mid, 1, 3, "ППР-2025 Энергоблок-1, перегрузка топлива", "ППР", "2025-07-01", "2025-07-30", 850_000_000, "Атомэнергоремонт"]); mid += 1
titles = [
    ("Ревизия ГЦН-2", "текущий"), ("Замена уплотнения ГЦН", "текущий"),
    ("Ремонт подшипника турбины", "аварийный"), ("Чистка конденсатора", "текущий"),
    ("Поверка каналов КИПиА", "текущий"), ("Ремонт арматуры 1 контура", "текущий"),
    ("Замена масла турбины", "текущий"), ("Ремонт трансформатора", "аварийный"),
    ("Опробование ДГ", "текущий"), ("Ремонт насоса САОЗ", "текущий"),
]
for i in range(38):
    unit = random.choice([1, 2])
    sys_id = random.choice([1, 2, 3] if unit == 1 else [4, 5, 6])
    title, wt = random.choice(titles)
    s = date(YEAR, random.randint(1, 12), random.randint(1, 25))
    e = s + timedelta(days=random.randint(1, 14))
    if e.year != YEAR:
        e = date(YEAR, 12, 28)
    cost = random.randint(500_000, 60_000_000)
    contractor = random.choice(["Атомэнергоремонт", "Своими силами", "Подрядчик ЭЛМОНТ", "Своими силами"])
    maint.append([mid, unit, sys_id, f"{title} №{i+1}", wt, s.isoformat(), e.isoformat(), cost, contractor])
    mid += 1

with open(OUT / "maintenance.csv", "w", newline="", encoding="utf-8") as f:
    csv.writer(f).writerows(maint)
print(f"maintenance: {len(maint)}")

# ---------- 6. SHIFT_SCHEDULE (график 2/2 для ~60 сменных) ----------
shift_workers = [e[0] for e in employees[:60]]
office_workers = [e[0] for e in employees[60:]]
sched = []
sched_id = 1
d = date(YEAR, 1, 1)
# сдвиг фазы чтобы не все в один день
phase = {emp: random.randint(0, 3) for emp in shift_workers}
while d <= date(YEAR, 12, 31):
    for emp in shift_workers:
        cycle = (d - date(YEAR, 1, 1)).days + phase[emp]
        if cycle % 4 in (0, 1):  # 2 рабочих / 2 выходных
            # отпуск 28 дней летом + больничные
            if date(YEAR, 8, 1) <= d <= date(YEAR, 8, 28) and emp % 5 == 0:
                continue
            if random.random() < 0.015:  # больничный/отгул
                continue
            shift = 1 if cycle % 4 == 0 else 2
            sched.append([sched_id, emp, shift, d.isoformat()])
            sched_id += 1
    # офисные — будни
    if d.weekday() < 5:
        for emp in office_workers:
            if random.random() < 0.06:  # отпуск/отгул
                continue
            sched.append([sched_id, emp, 3, d.isoformat()])
            sched_id += 1
    d += timedelta(days=1)

with open(OUT / "shift_schedule.csv", "w", newline="", encoding="utf-8") as f:
    csv.writer(f).writerows(sched)
print(f"shift_schedule: {len(sched)}")

# ---------- 7. DOSIMETRY (ежемесячно + повышенные у ремонтников в ППР) ----------
dosi = []
did = 1
for e in employees:
    emp_id, dept = e[0], e[2]
    for m in range(1, 13):
        base = 0.15 if dept in (1, 6) else 0.08
        dose = max(0, gauss(base, 0.08))
        # в июле ремонтники хватают больше
        if m == 7 and dept in (1, 2, 4):
            dose += abs(gauss(0.9, 0.4))
        dosi.append([did, emp_id, date(YEAR, m, 28).isoformat(), round(dose, 3)])
        did += 1

with open(OUT / "dosimetry.csv", "w", newline="", encoding="utf-8") as f:
    csv.writer(f).writerows(dosi)
print(f"dosimetry: {len(dosi)}")

total = len(employees) + len(readings) + len(gen) + len(alarms) + len(maint) + len(sched) + len(dosi)
print(f"TOTAL fact+dict rows: {total}")
