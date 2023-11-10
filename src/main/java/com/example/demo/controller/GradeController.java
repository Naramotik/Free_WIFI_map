package com.example.demo.controller;

import com.example.demo.dto.GradeToPost;
import com.example.demo.model.Grade;
import com.example.demo.model.Mark;
import com.example.demo.service.GradeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/grade")
public class GradeController {
    @Autowired
    GradeService gradeService;

    @PostMapping
    public Grade save(@RequestBody GradeToPost gradeToPost){
        return gradeService.save(gradeToPost);
    }

    @GetMapping("/{latitude}")
    public ResponseEntity<List<Grade>> getGradesFromMark(@PathVariable String latitude){
        return new ResponseEntity<List<Grade>> (gradeService.findGrades(latitude), HttpStatus.OK);
    }
}
