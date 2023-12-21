package com.example.demo.controller;

import com.example.demo.dto.MarkToPost;
import com.example.demo.model.Client;
import com.example.demo.repository.ClientRepository;
import com.example.demo.repository.MarkRepository;
import com.example.demo.model.Mark;
import com.example.demo.service.ClientService;
import com.example.demo.service.MarkService;
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
    MarkService markService;

    @PostMapping
    public ResponseEntity<Mark> createMark(@RequestBody MarkToPost markToPost){
        System.out.println(markToPost);
        return new ResponseEntity<Mark> (markService.save(markToPost), HttpStatus.OK);
    }
    @GetMapping
    public ResponseEntity<List<Mark>> getAllMarks(){
        return new ResponseEntity<List<Mark>> (markService.findAll(), HttpStatus.OK);
    }

    @GetMapping("/{longitude}")
    public ResponseEntity<Mark> getMark(@PathVariable String longitude){
        return new ResponseEntity<Mark> (markService.getMark(longitude), HttpStatus.OK);
    }

    @DeleteMapping("/{longitude}/{user_email}")
    public String delete(@PathVariable String longitude,
                       @PathVariable String user_email){
        return markService.delete(longitude, user_email);
    }

}

