select /*+leading(t1) use_nl(t2)*/ * from t1,t2 on t1.id=t2.t1_id where t1.n=19;

