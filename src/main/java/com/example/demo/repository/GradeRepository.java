package com.example.demo.repository;

import com.example.demo.model.Client;
import com.example.demo.model.Grade;
import com.example.demo.model.Mark;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GradeRepository extends JpaRepository<Grade, Long> {
    List<Grade> findByMark(Mark mark);
    List<Grade> findByClient(Client client);

}
