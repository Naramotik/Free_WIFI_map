package com.example.demo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@CrossOrigin(origins = "http://localhost:3000")
@RequestMapping("/mark")
public class MarkController {

    @Autowired
    MarkRepository markRepository;

    @PostMapping
    public HttpStatus createMark(@RequestBody Mark mark){
        System.out.println(mark);
        markRepository.save(mark);
        return HttpStatus.CREATED;
    }
    @GetMapping
    public ResponseEntity<List<Mark>> getAllMarks(){
        return new ResponseEntity<List<Mark>> (markRepository.findAll(), HttpStatus.OK);
    }

}

