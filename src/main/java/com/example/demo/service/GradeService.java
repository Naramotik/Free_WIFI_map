package com.example.demo.service;

import com.example.demo.dto.GradeToPost;
import com.example.demo.model.Client;
import com.example.demo.model.Comment;
import com.example.demo.model.Grade;
import com.example.demo.model.Mark;
import com.example.demo.repository.GradeRepository;
import com.example.demo.repository.MarkRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class GradeService {
    @Autowired
    GradeRepository gradeRepository;
    @Autowired
    ClientService clientService;
    @Autowired
    MarkRepository markRepository;

    public Grade save(GradeToPost gradeToPost){
        Client client = clientService.findClientByEmail(gradeToPost.getEmail());
        Mark mark = markRepository.findByLatitude(gradeToPost.getLatitude()).get();
        Grade grade = Grade.builder().score(gradeToPost.getGrade()).client(client).mark(mark).build();
        return gradeRepository.save(grade);
    }
    public List<Grade> findGrades(String latitude){
        Optional<Mark> mark = markRepository.findByLatitude(latitude);
        return gradeRepository.findByMark(mark.get());
    }
}
